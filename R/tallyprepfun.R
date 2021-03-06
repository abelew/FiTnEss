## tallyprepfun
## 1. usable tally file preparation

#' Get the set of useful TAs from a tally file, I think.
#'
#' @param strain Which strain?
#' @param file_location Where is the tally file?
#' @return Set of tallies to use.
#' @export
tallyprepfun <- function(strain, file_location) {
####################### Usable tally file preparation #######################
  print("Starting Phase I: preparing usable tally files")
  usable_tally_list <- list()
  file_location_list <- unlist(strsplit(file_location, ","))

  ## 1. load in supporting files
  if (strain %in% c("UCBPP", "PA14", "pa14", "ucbpp")) {
    strain <- "UCBPP"
    st <- "PA14"
  } else {
    st <- strain
  }
  nm <- paste(st, "_support", sep = "")

  load("data/support_list.rda")
  support_list <- support_list[[strain]]
  nonPermissiveTA <- support_list[[1]]
  homo <- support_list[[2]]
  genelist <- support_list[[3]]
  geneinfo <- support_list[[4]]

  load("data/cluster.rda")
  cluster2 <- cluster %>%
    dplyr::filter(strain == st) %>%
    dplyr::select(Locus.CIA, strain, desc)

  colnames(genelist) <- c("V1", "Locus.CIA", "gene_start", "gene_stop")
  genelist$strain <- st
  colnames(geneinfo) <- c("type", "strand", "Locus.CIA")
  genelist <- genelist %>%
    dplyr::full_join(geneinfo, by = "Locus.CIA")
  genelist <- genelist %>%
    dplyr::left_join(cluster2, by = c("Locus.CIA", "strain"))
  genelist <- genelist %>%
    dplyr::select(Locus.CIA, strain, type, gene_start,
                  gene_stop, strand, desc)

  if (strain == "UCBPP") {
    genelist$strain <- "UCBPP"
  } else {
    genelist$strain <- genelist$strain
  }
  print("Finished loading supporting files")

  ## 2. prepare usable tally files
  usable_tally_list <- lapply(file_location_list, function(x) {
    unique_file = x
    print(unique_file)
    ## a) Import raw tally files and annotate sites with homologous:
    unique_map_tally <- import_raw_tally(unique_file, CIA = FALSE)
    unique_map_tally <- find_homo(unique_map_tally, homo)
    unique_map_tally2 <- unique_map_tally
    unique_map_tally2$Locus.CIA <- gsub("IG_", "", unique_map_tally2$Locus.CIA)
    unique_map_tally2$strain <- strain
    ## b) Import raw tally files and annotate sites with multialignment:
    unique_map_tally <- calc_TApos(unique_map_tally2, genelist)
    ## removed many TA sites
    unique_map_tally <- dplyr::filter(unique_map_tally, type == "CDS")
    tally.w <- unique_map_tally
    ## c) Find sites affected by non-permissive bias:
    tally.w$non_permissive <- (tally.w$TA_start %in% nonPermissiveTA$V2)
    table(tally.w$non_permissive)  #TRUE is number of non-permissive TA sites
    ## d) Denote TAs for edge trimming
    tally.w <- denote_coreTA(tally.w, 50)
    ## denote TAs as TRUE it is not in the first and last 50bp of the gene
    table(tally.w$coreTA)  #false is number of TA sites found near edges
    ## e) process to list for downstream analysis
    x <- tally.w
  })
  return(usable_tally_list)
}
