                                        # callessfun 3. calculate essential genes

#' Perform the actual calling of essentiality.
#'
#' @param file_location What to parse for the calls.
#' @param usable_tally_list Subset of the tally.txt to call.
#' @param parameter_list The parameters from calcparafun().
#' @return Essentiality!
#' @export
callessfun <- function(file_location, usable_tally_list, parameter_list) {
  file_location_list <- unlist(strsplit(file_location, ","))
  filtered_list <- lapply(usable_tally_list, function(x) {
    x <- x %>%
      dplyr::filter(homo == FALSE,
                    non_permissive == FALSE,
                    coreTA == TRUE)
  })

####################### Call Essentials #######################
  print("Starting Phase III: calling Essentials")
  result_list <- list()
  repvec <- seq_len(length(unique(file_location_list)))

  result_list <- lapply(seq_len(length(unique(file_location_list))), function(x) {
    data <- filtered_list[[x]]
    strain <- unique(data$strain)
    oridata <- data
    totdata <- oridata %>%
      dplyr::select(Locus.CIA, n) %>%
      dplyr::group_by(Locus.CIA) %>%
      dplyr::summarise(gtot = sum(n), Nta = n())
    totdata <- totdata %>%
      dplyr::group_by(Nta) %>%
      dplyr::mutate(ngene = n()) %>%
      dplyr::ungroup()

    para <- parameter_list
    lp <- para[[x]]$lp[which(para[[x]]$cvm == min(para[[x]]$cvm))]
    sigma <- para[[x]]$sigma[which(para[[x]]$cvm == min(para[[x]]$cvm))]

    ngene <- totdata %>%
      dplyr::ungroup() %>%
      dplyr::group_by(Nta) %>%
      dplyr::summarise(ngene = n())

    plist <- lapply(seq_len(length(ngene$Nta)), function(x) {
      lbd1 <- 1 / rlnorm(10000, meanlog = lp, sdlog = sigma)
      Zg1 <- rnbinom(1e+06, ngene$Nta[x], lbd1)
      Zg2 <- rnbinom(1e+06, ngene$Nta[x], 0.7)
      subtot <- totdata %>%
        dplyr::filter(Nta == ngene$Nta[x])
      subtot2 <- subtot %>%
        dplyr::rowwise() %>%
        dplyr::mutate(pv1 = length(which(Zg1 <= gtot)) / length(Zg1),
                      pv2 = length(which(Zg2 >= gtot)) / length(Zg2))  #pv2: the larger the better
      subtot3 <- subtot2
      x <- subtot3
    })
    names(plist) <- paste("Nta", ngene$Nta, sep = "_")
    pdata1 <- do.call("rbind", plist)

    ## adjusted p-value

    pdata1 <- pdata1 %>%
      dplyr::select(Locus.CIA:pv1)
    colnames(pdata1)[5] <- "pvalue"
    ## FWER
    pdata1$padj <- p.adjust(pdata1$pvalue)
    pdata1$Ess_fwer <- "NE_fwer"
    pdata1$Ess_fwer[which(pdata1$padj < 0.05)] <- "E_fwer"
    ## FDR
    pdata1$pfdr <- p.adjust(pdata1$pvalue, "fdr")
    pdata1$Ess_fdr <- "NE_fdr"
    pdata1$Ess_fdr[which(pdata1$pfdr < 0.05)] <- "E_fdr"
    x <- pdata1
  })

  print("Finished running, save...")
  names(result_list) <- names(parameter_list)
  return(result_list)
}
