#fitnessRun_function
#Oct23_2018_FiTnEss_separate
#Oct23_2018_FiTnEss

#4. function to calculate parameters using Nta=median(Nta)

fitnessRun<-function(strain,file_location,save_location,repeat_time=3){ #pre-defined as using Nta=10, and replicate for 5 times for each replicate

  library(dplyr)
  library(tidyr)
  library(openxlsx)
  source("R/import_txt.R")
  source("R/find_homo2.R")
  source("R/calc_TApos.R")
  source("R/denode_coreTA.R")
  source("R/my_cvm.R")
  source("R/jointfun4.R")
  source("R/tallyprepfun.R")
  source("R/calcparafun.R")
  source("R/callessfun.R")

  ####################### Usable tally file preparation #######################

  usable_tally_list<-tallyprepfun(strain,file_location)

  ####################### Calculating parameters #######################

  parameter_list<-calcparafun(strain,usable_tally_list,save_location,rep_time=repeat_time)

  ####################### Call Essentials #######################

  result_list<-callessfun(file_location,usable_tally_list,parameter_list)

  #save final results

  write.xlsx(result_list, file = save_location)
  print("Final results saved, finished running.")

}
