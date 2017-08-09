#!/usr/bin/env bash

###################################################################
#  ☭  ☭  ☭  ☭  ☭  ☭  ☭  ☭  ☭  ☭  ☭  ☭  ☭  ☭  ☭  ☭  ☭  ☭  ☭  ☭  ☭  #
###################################################################

###################################################################
# SPECIFIC MODULE HEADER
# This module performs elementary network analyses.
###################################################################
mod_name_short=fcon
mod_name='FUNCTIONAL CONNECTOME MODULE'
mod_head=${XCPEDIR}/core/CONSOLE_MODULE_RC

###################################################################
# GENERAL MODULE HEADER
###################################################################
source ${XCPEDIR}/core/constants
source ${XCPEDIR}/core/functions/library.sh
source ${XCPEDIR}/core/parseArgsMod

#################################################################f##
# MODULE COMPLETION AND ANCILLARY FUNCTIONS
###################################################################
update_networks() {
   atlas_add      ${a_name}   Map               ${nodemap[${cxt}]}
   atlas_add      ${a_name}   Timeseries        ${ts[${cxt}]}
   atlas_add      ${a_name}   MatrixFC          ${adjacency[${cxt}]}
   atlas_add      ${a_name}   Pajek             ${pajek[${cxt}]}
   atlas_add      ${a_name}   MissingCoverage   ${missing[${cxt}]}
   atlas_add      ${a_name}   DynamicFC         ${ts_edge[${cxt}]}
   atlas_config   ${a_name}   Space             ${space}
}

completion() {
   write_atlas
   
   source ${XCPEDIR}/core/auditComplete
   source ${XCPEDIR}/core/updateQuality
   source ${XCPEDIR}/core/moduleEnd
}





###################################################################
# OUTPUTS
###################################################################
configure      mapbase                 ${out}/${prefix}_atlas

<< DICTIONARY

THE OUTPUTS OF FUNCTIONAL CONNECTOME ANALYSIS ARE PRIMARILY
DEFINED IN THE LOOP OVER NETWORKS.

adjacency
   The connectivity matrix or functional connectome.
mapbase
   The base path to any parcellations or ROI atlantes that have
   been transformed into analyte space.
missing
   An index of network nodes that are insufficiently covered and
   consequently do not produce meaningful output.
nodemap
   The map of the network's nodes, warped into analyte space.
pajek
   A representation of the network as a sparse matrix. Used by
   some network science software packages.
ts
   The mean local timeseries computed in each network node.
ts_edge
   The timeseries computed in each network edge using the
   multiplication of temporal derivatives (MTD).

DICTIONARY










###################################################################
# Retrieve all the networks for which analysis should be run, and
# prime the analysis.
###################################################################
if [[ -e ${fcon_atlas[${cxt}]} ]]
   then
   subroutine                 @0.1
   add_reference     referenceVolume[${subjidx}]   ${prefix}_referenceVolume
   load_atlas        ${fcon_atlas[${cxt}]}
   load_atlas        ${atlas[${subjidx}]}
else
   echo \
"
::XCP-WARNING: Functional connectome analysis has been requested, 
  but no network maps have been provided.
  
  Skipping module"
   exit 1
fi





###################################################################
# Iterate through all networks.
#
# In brief, the functional connectome analysis process consists of
# the following steps:
#  1. Generate a map of the current network if it does not already
#     exist, and move the map from anatomical space into BOLD
#     space.
#  2. Extract mean timeseries from each node of the network.
#  3. Compute the adjacency matrix from the mean node timeseries.
#  4. Compute a mean edge timeseries from the mean node timeseries.
###################################################################
for net in ${atlas_names[@]}
   do
   atlas_parse ${net}
   [[ -z ${a_map} ]] && continue
   routine                    @1    Functional connectome: ${a_name}
   ################################################################
   # Define the paths to the potential outputs of the current
   # network analysis.
   ################################################################
   configure   fcdir                ${outdir}/${a_name}
   configure   fcbase               ${fcdir[${cxt}]}/${prefix}_${a_name}
   configure   nodemap              ${mapbase[${cxt}]}/${prefix}_${a_name}.nii.gz
   configure   ts                   ${fcbase[${cxt}]}_ts.1D
   configure   adjacency            ${fcbase[${cxt}]}_network.txt
   configure   pajek                ${fcbase[${cxt}]}.net
   configure   missing              ${fcbase[${cxt}]}_missing.txt
   configure   ts_edge              ${fcbase[${cxt}]}_tsEdge.1D
   ################################################################
   # [1]
   # Based on the type of network map and the space of the primary
   # BOLD timeseries, decide what is necessary to move the map
   # into the BOLD timeseries space.
   ################################################################
   subroutine                 @1.2  Mapping network to image space
   ################################################################
   # If the network map has already been computed in this space,
   # then move on to the next stage.
   ################################################################
   if is_image ${nodemap[${cxt}]} \
   && ! rerun
      then
      subroutine              @1.2.1
      a_type=done
   fi
   mkdir -p ${fcdir[${cxt}]}
   case ${a_type} in
   Map)
      subroutine              @1.2.2
      #############################################################
      # Ensure that the network has more than one node, then map
      # it into the analyte space.
      #############################################################
      rm -f ${nodemap[${cxt}]}
      range=( $(exec_fsl fslstats ${a_map} -R) )
      if (( $(arithmetic ${range[1]}\<=1) == 1 ))
         then
         subroutine           @1.2.3   Skipping ${a_name}: Not a well-formed node system
         continue
      fi
      warpspace atlas:${a_name} ${nodemap[${cxt}]} ${space} MultiLabel
      ;;
   Coordinates)
      subroutine              @1.2.4
      output      node_sclib           ${mapbase[${cxt}]}${a_name}.sclib
      if (( ${a_nodes} <= 1 ))
         then
         subroutine           @1.2.5
         continue
      fi
      #############################################################
      # If the primary BOLD timeseries is in native space, use
      # ANTs to transform spatial coordinates into native space.
      # This process is much less intuitive than it sounds,
      # largely because of the stringent orientation requirements
      # within ANTs, and it is cleverly tucked away behind a
      # utility script called pointTransform.
      #
      # Also, note that antsApplyTransformsToPoints (and
      # consequently pointTransform) requires the inverse of the
      # transforms that you would intuitively expect it to
      # require.
      #############################################################
      case std2${space} in
      std2native)
         subroutine           @1.2.6
         ##########################################################
         # Apply the required transforms.
         ##########################################################
         rm -f ${node_sclib[${cxt}]}
         exec_xcp pointTransform \
            -v \
            -i ${a_map} \
            -s ${template} \
            -r ${referenceVolume[${subjidx}]} \
            $coreg \
            $rigid \
            $affine \
            $warp \
            $resample \
            $trace_prop \
            >> ${node_sclib[${cxt}]}
         ;;
      #############################################################
      # Coordinates are always in standard space, so if the
      # primary BOLD timeseries has already been normalised, then
      # there is no need for any further manipulations.
      #############################################################
      std2standard)
         subroutine           @1.2.7
         ;;
      esac
      #############################################################
      # Use the (warped) coordinates and radius to generate a map
      # of the network.
      #############################################################
      subroutine              @1.2.8
      exec_xcp coor2map \
         ${traceprop} \
         -i ${node_sclib[${cxt}]} \
         -t ${referenceVolumeBrain[${subjidx}]} \
         -o ${nodemap[${cxt}]}
      ;;
   done)
      subroutine              @1.2.9
      ;;
   esac
   ################################################################
   # Update the path to the network map
   ################################################################
   add_reference nodemap[${cxt}] ${a_name}/${prefix}_${a_name}
   
   
   
   
   
   ################################################################
   # [2]
   # Compute the mean local timeseries for each node in the
   # network.
   ################################################################
   if [[ ! -s ${ts[${cxt}]} ]] \
   || rerun
      then
      subroutine              @1.3  Computing network timeseries
      exec_sys rm -f ${ts[${cxt}]}
      exec_xcp roi2ts.R \
         -i ${img} \
         -r ${nodemap[${cxt}]} \
         >> ${ts[${cxt}]}
   fi





   ################################################################
   # [3]
   # Compute the adjacency matrix based on the mean local
   # timeseries.
   ################################################################
   if [[ ! -s ${pajek[${cxt}]} ]] \
   || rerun
      then
      subroutine              @1.4  Computing adjacency matrix
      exec_sys rm -f ${adjacency[${cxt}]}
      exec_sys rm -f ${pajek[${cxt}]}
      exec_sys rm -f ${missing[${cxt}]}
      exec_xcp ts2adjmat.R -t ${ts[${cxt}]} >> ${adjacency[${cxt}]}
      exec_xcp adjmat2pajek.R \
         -a ${adjacency[${cxt}]} \
         -t ${fcon_thr[${cxt}]} \
         >> ${pajek[${cxt}]}
      ################################################################
      # Flag nodes that fail to capture any signal variance.
      ################################################################
      subroutine              @1.5  Determining node coverage
      unset missing_arg
      badnodes=$(exec_xcp missingIdx.R -i ${adjacency[${cxt}]})
      if [[ -n ${badnodes} ]]
         then
         echo "${badnodes}" >> ${missing[${cxt}]} \
         missing_arg=",'missing','${missing[${cxt}]}'"
      fi
   fi





   ################################################################
   # [4]
   # Compute the mean timeseries for each edge of the network.
   # This is also called dynamic connectivity.
   ################################################################
   if (( ${fcon_window[${cxt}]} != 0 ))
      then
      subroutine              @1.6  Computing dynamic connectome
      if [[ ! -s ${ts_edge[${cxt}]} ]] \
      || rerun
         then
         subroutine           @1.6.1   Window: ${fcon_window[${cxt}]} TRs
         exec_sys rm -f ${ts_edge[${cxt}]}
         exec_xcp mtd.R \
            -t ${ts[${cxt}]} \
            -w ${fcon_window[${cxt}]} \
            -p ${fcon_pad[${cxt}]} \
            >> ${ts_edge[${cxt}]}
      fi
   fi
   update_networks
   routine_end
done

completion
