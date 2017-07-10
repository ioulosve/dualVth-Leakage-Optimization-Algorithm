
#command to convert a collection into a list

proc coll_to_list { collection } {
  set lista {} 
  foreach_in_collection coll $collection { lappend lista [get_object_name $coll]}
  return $lista
}


######################################################################################

#command to swap cells

proc cell_swapping {cell_list TH {flag 0} {cell_to_swap -1} {constraint 0}} {

set vth 0
set dummy 0
set swapped_cells_numb 0


foreach cell $cell_list {
	
	
	set org [get_attribute [get_cells $cell] ref_name]
	#puts "original $org"
	set alt [get_attribute [get_alternative_lib_cells $cell] full_name]
	#puts $alt
	##avoid sizing by choosing only cells with same area of original one
	regexp {X(\d+)$} $org -> org_area
	#puts "original area $org_area"

	if {$flag == 1} {
			 set path [get_timing_paths]
			 set slack [get_attribute $path slack]
			 #puts "Slack inside: $slack"
			 if {$slack >= 0} {
						  return $swapped_cells_numb
			 }
  }
	
	if { ($swapped_cells_numb == $cell_to_swap) && ($constraint == "hard")} {
			return $swapped_cells_numb
	}
		
	foreach sw_cell $alt {
	
	   if { $TH == "LVT"} {
			set y [ regexp {.+_L(L).}  $org -> dummy]
				if {$y==1} {
					break
				}
			#check if org is LH
			set LHflag [regexp {.+_LH_(.+)} $org  -> subname]
			#check if org is LHS
			set LHSflag [regexp {.+_LHS_(.+)} $org  -> subname]
			
			if {$LHflag == 1} {
				set check [regexp ".+_LL_$subname$" $sw_cell]
				if {$check == 1} {
			            set sz [swap_cell $cell $sw_cell]
								     if {$sz==1} {
										  # puts "$org swapped-> $sw_cell"
									       set swapped_cells_numb [expr $swapped_cells_numb + 1]
									}
			            	break
						   }
			}
			if {$LHSflag == 1} {
				set check [regexp ".+_LLS_$subname$" $sw_cell]
				if {$check == 1} {
			             set sz [swap_cell $cell $sw_cell]
								     if {$sz==1} {
										  # puts "$org swapped-> $sw_cell"
									       set swapped_cells_numb [expr $swapped_cells_numb + 1]
								     }
			            	break
						   }
			   }
						   
		        
	     }
	      if { $TH == "HVT"} {
		  set y [ regexp {.+_L(H).}  $org -> dummy]
				if {$y==1} {
					break
				}
			#check if org is LL
			set LLflag [regexp {.+_LL_(.+)} $org  -> subname]
			#check if org is LLS
			set LLSflag [regexp {.+_LLS_(.+)} $org  -> subname]
			
			if {$LLflag == 1} {
				set check [regexp ".+_LH_$subname$" $sw_cell]
				#puts "sw_cell vale $sw_cell -- check vale $check"

				if {$check == 1} {
			                 set sz [swap_cell $cell $sw_cell]
								     if {$sz==1} {
										  # puts "$org swapped-> $sw_cell"
									       set swapped_cells_numb [expr $swapped_cells_numb + 1]
								     }
			            	break
						   }
			}
			if {$LLSflag == 1} {
				set check [regexp ".+_LHS_$subname$" $sw_cell]
				if {$check == 1} {
			                 set sz [swap_cell $cell $sw_cell]
								     if {$sz==1} {
										  # puts "$org swapped-> $sw_cell"
									       set swapped_cells_numb [expr $swapped_cells_numb + 1]
								     }
			            	break
						   }
			}
			
	       }
	 }
  
	
	}
				
				return $swapped_cells_numb
}

######################################################################################

#command that extracts the cells of the critical path
proc path_cells { path } {

	
    

	set obj_list ""
        set timing_points [sort_collection [get_attribute $path points] slack]
 	foreach_in_collection timing_point $timing_points {
		lappend obj_list [get_attribute $timing_point object]
	}

	set cells [get_cells -of_objects $obj_list]
	set cell_list [coll_to_list $cells]
	return $cell_list
}





#####################################################################################

#DUALVTH COMMAND


proc dualVth {args} {
  
  puts "                                                 "
	puts "   ###########################################   "
	puts "   ### DualVth Low-power Contest - Group 5 ###   "
	puts "   ###########################################   "
	puts "                                                 "

	parse_proc_arguments -args $args results
	set lvt $results(-lvt)
	set constraint $results(-constraint)

	#################################
	### INSERT YOUR COMMANDS HERE ###
	#################################

suppress_message RC-004
suppress_message PTE-003
suppress_message UID-401
suppress_message ENV-003
suppress_message UITE-489
suppress_message CMD-041
suppress_message LNK-041
suppress_message NED-045
suppress_message SEL-002
suppress_message NED-057
suppress_message UITE-502
##########################

set_user_attribute [find library CORE65LPLVT] default_threshold_voltage_group LVT
set_user_attribute [find library CORE65LPHVT] default_threshold_voltage_group HVT


##################################################################


	if {$lvt > 1 || $lvt <0} {
    		puts "ERROR: Percentage must be in the range \[0-1\]"
   		return
  	}
	
set start_time [clock seconds]

  #check if slack is negative with all LVT
  set path [get_timing_paths]
  set slack [get_attribute $path slack]
  set stop_flag 0
  if {$slack < 0} {
	#check if circuit is made only of LVT cells
	set allcells [get_cells]
	set prime_ref_names [get_attribute [get_cells] ref_name]
	foreach element $prime_ref_names {
		set y [ regexp {.+_L(H).}  $element -> dummy]
				if {$y==1} {
					set stop_flag 1
					break
				}
	} 
  	if {$stop_flag == 0} {
		puts "No optimization can be done, slack is negative with all LVT cells"
		puts "Slack: $slack"
		
		set end_time [clock seconds]
		set duration [expr $end_time - $start_time]
		puts "### EXECUTION TIME: $duration seconds ###"
		return
	}
  }

	#swapping all cells to HVT
  set coll [get_cells]
  set total_cell [sizeof_collection $coll]
  puts "Total number of cells: $total_cell"
  set max_swap_cell [expr $total_cell*$lvt]
  set max_swap_cell [expr {int($max_swap_cell)}]
  set swappable $max_swap_cell
  puts "MAX number of swappable cells: $max_swap_cell"
  set cell_list [coll_to_list $coll]
  set ref_names [get_attribute $coll ref_name]
	puts "Swapping all cells to HVT..."
  set HVTswapped [cell_swapping $cell_list "HVT" 0]
  set curr_lvt 0
 

set path [get_timing_paths]
set slack [get_attribute $path slack]
set total_swapped 0
set flag_terminate 0
set flag_opt 0
set swapped 0
set cell_list_length 0


if {$slack < 0} {
 puts "Value of the slack with all HVT cells: $slack. Slack is negative"
 puts "Starting optimization.."
} else {
	puts "NO OPTIMIZATION NEEDED. Slack is positive with all HVT cells"
	puts "Slack: $slack"
	report_threshold_voltage_group

	set end_time [clock seconds]
	set duration [expr $end_time - $start_time]
	puts "### EXECUTION TIME: $duration seconds ###"
	return 
}

 
while {$slack <0 } {
			if { $max_swap_cell < 1 && $constraint == "hard" } {
					#slack is negative but all requested cells are swapped.
					set flag_terminate 1
					break;
				}
			
			#swap until the slack and the percentage constraints are satified	
			set path [get_timing_paths -max_paths 5]
			#get cells of the critical path
			set cp_cells [path_cells $path]
  			
			
			set cell_list_length [llength $cp_cells]
			
				
			#swapping all cells of the current critical path and update the counter
			set swapped [cell_swapping $cp_cells "LVT" 0]
			
			puts -nonewline "Slack: $slack , swapped: $total_swapped \r"
			flush stdout
			
		
			if {$swapped == 0} {
					puts "Slack: $slack , swapped: $total_swapped"
					puts "Further optimizations..."
					set regs [coll_to_list [get_cells -filter !is_combinational]]							           
					set comb [coll_to_list [get_cells -filter is_combinational]]
					set othercells [concat $comb $regs]
					set temp [expr $swappable - $total_swapped]
					set swapped [cell_swapping $othercells "LVT" 0 $temp $constraint]
					 

					
							set non_critical [get_timing_paths -slack_greater_than 0 -max_paths 100000]
							set non_critical [sort_collection -descending $non_critical slack]
							foreach_in_collection path $non_critical {
								  set cp_cells [path_cells $path]
									set swapped [cell_swapping $cp_cells "HVT"]							
									set total_swapped [expr $total_swapped + $swapped]
									set slack2 [get_attribute [get_timing_paths] slack]
									if { $slack2 < 0 } {
											set swapped [cell_swapping $cp_cells "LVT"]
											break
									 }
								 }
           
			}
			
			set total_swapped [expr $total_swapped + $swapped]
			#updating max swappable cells
			set max_swap_cell [expr $max_swap_cell - $swapped]
			set path2 [get_timing_paths]
			set slack [get_attribute $path2  slack]
			
                        
			}


				
			if {$swappable >0 || $constraint == "soft"} {		
					
					set total_swapped [expr $total_swapped - $cell_list_length]
					
					set swapped [cell_swapping $cp_cells "HVT" 0]
					foreach cell_cp $cp_cells {
						set swapped [cell_swapping $cell_cp "LVT" 0]
						set total_swapped [expr $total_swapped + $swapped]
						set path2 [get_timing_paths] 
						set slack [get_attribute $path2  slack]
						
						if {($slack >= 0) || ($total_swapped == $swappable && $constraint == "hard")} {
							
							break;			
						}
						
		
					}
					}
					
				
			if {$slack >=0} {
				puts "Optimization completed. Slack: $slack (MET)"
			} else {
				puts "Optimization has not reached timing requirements."
				puts "Slack: $slack (VIOLATED)"

			}
			puts "Total cells swapped: $total_swapped"
			report_threshold_voltage_group

			set end_time [clock seconds]

			set duration [expr $end_time - $start_time]
			puts "### EXECUTION TIME: $duration seconds ###"

      

	return
}


define_proc_attributes dualVth \
-info "Post-Synthesis Dual-Vth cell assignment" \
-define_args \
{
	{-lvt "maximum % of LVT cells in range [0, 1]" lvt float required}
	{-constraint "optimization effort: soft or hard" constraint one_of_string {required {values {soft hard}}}}
}
