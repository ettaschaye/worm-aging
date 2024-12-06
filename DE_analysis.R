library(monocle3)
library(dplyr)
library(ggplot2)
library(UpSetR)

d1cds <- load_mm_data(mat_path = "~/Desktop/Qbb_project_data/day1/matrix.mtx", 
                      feature_anno_path = "~/Desktop/Qbb_project_data/day1/features.tsv", 
                      cell_anno_path = "~/Desktop/Qbb_project_data/day1/barcodes.tsv")

d8cds <- load_mm_data(mat_path = "~/Desktop/Qbb_project_data/day8/matrix.mtx", 
                      feature_anno_path = "~/Desktop/Qbb_project_data/day8/features.tsv", 
                      cell_anno_path = "~/Desktop/Qbb_project_data/day8/barcodes.tsv")



cds_combined <- combine_cds(list(d1cds, d8cds))
#combine cell data sets 

cds <- preprocess_cds(cds_combined, num_dim = 100)
#normalized with PCA (100 PCs)

plot_pc_variance_explained(cds)
#Shows that 100 PCs explain most of the variance in the data set

cds <- reduce_dimension(cds)

plot_cells(cds)
#Reduce dimensionality and plot with UMAP 


colData(cds) #Shows how the cells are annotated by the authors (Sample 1 is Day1, sample 2 is Day15)
#Day1 has 11000 cells, Day15 has 888 cells. Datasets are combined into a single cds. 
length(colData(cds)$sample[colData(cds)$sample == 2])

plot_cells(cds) #Shows there is significant differences in gene expression between Day1 and Day15 (but maybe this could be because there are so many less cells in Day15?)
# Just from eyeballing it, it looks like there are certain cell types that are overepresented in the D15 data set (and many that are underepresented)
# I don't think this is a batch effect we should control for, as we do expect to see expression variation between these timepoints 
# I think we should find another timepoint that more closely matches the clusters seen in Day1. 

#Now that I have switched to Day11, cluster representation is better but not great. 
# Day 8 a little better. 10,000 (day1) vs 7,890 (day8) cells. 

#control for batch effects (day1 vs day8)
cds <- align_cds(cds, num_dim = 100, alignment_group = "sample")
cds <- reduce_dimension(cds)


  
#when controlling for batch effects, Day1 and Day8 look really good! You could do a lot with a DE analysis between timepoints with this I think. 


cds <- cluster_cells(cds, resolution=1e-5)
plot_cells(cds)
plot_cells(cds, color_cells_by="cluster", group_cells_by="cluster")
colData(cds)$cluster <- as.character(clusters(cds))
colData(cds)$Timepoint <- as.character(colData(cds)$sample)

plot_cells(cds, color_cells_by="Timepoint", label_cell_groups=FALSE) + 
  scale_color_manual(name = "Timepoint",
                     values=c("#e41a1c", "#377eb8"),
                     labels=c("Day 1", "Day 8"))

#Finding markers per cluster
marker_test_res <- top_markers(cds, group_cells_by="cluster", 
                               reference_cells=1000, cores=8)

marker_test_res %>%
  filter(cell_group == 4) %>%
  arrange(marker_test_p_value) %>%
  View()
#WBGene00006436 body wall musculature, muscle cell, reproductive, vulval muscle, 
#WBGene00006820 gonad, intestinal muscle, pharyngeal muscle cell, tail, vulval muscle, anal depressor muscle, anal sphincter muscle, 
#WBGene00006759 pharyngeal muscle, vulval muscle, 
#WBGene00002280 rectal muscle, reproductive system, spermatheca, tail ganglion, tail neuron, vulval muscle, anal depressor muscle, PVT, uterine muscle, body wall musculature, coelomocite, head, head neuron, nervous system
#WBGene00001386 vulval muscle, body wall musculature, male, vulval muscle
#WBGene00001328 vulva, vulval muscle, anal depressor muscle, basal lamina, body wall musculature, gonad, intestine, 
#cluster 4 is likely muscle cells

marker_test_res %>%
  filter(cell_group == 1) %>%
  arrange(marker_test_p_value) %>%
  View()
#WBGene00004798 gonad, 
#WBGene00020588 germ line, 
#WBGene00003955 germ line, 
#WBGene00001598 germ line, 
#WBGene00008218 germ line,
#WBGene00002073 germ line, 
#cluster 1 is definitely gonad

marker_test_res %>%
  filter(cell_group == 13) %>%
  arrange(marker_test_p_value) %>%
  View()

#Cluster 13 is neurons
#WBGene00008610 VA neuron, VB neuron, VC neuron, DA neuron, DB neuron, 
#WBGene00006831 ventral cord neuron, ventral nerve cord, AWCL/R, PLML, PLMR, dorsal nerve cord, lateral nerve cord, nerve ring, neuron, 
#WBGene00000175 muscle cell, 
#WBGene00006756 nerve ring, pharyngeal neuron, tail, VA neuron, VB neuron, VC nueron, ventral cord neuron, ventral nerve cord, CA1-8, CA9, CEMDL/R, HOB, R1AL/R, R2AL/R, an insane amount of other specific neurons
#WBGene00012128 ventral cord neuron, 
#WBGene00012759 ventral nerve cord, SABD, cholinergic neuron, other specific neurons


#subset cluster 4 (Muscle)
cds_cl4 <- cds[,colData(cds)$cluster == 4]
plot_cells(cds_cl4, color_cells_by = "Timepoint")
#DE analysis based on age
#Normalized_effect is equal to log2FC
gene_fits <- fit_models(cds_cl4, model_formula_str = "~Timepoint")
fit_coefs <- coefficient_table(gene_fits)
cl4dat <- fit_coefs %>%
  filter(normalized_effect != 0 ) %>%
  arrange(q_value) %>%
  filter(q_value < 0.05) 
#Should be able to make a volcano plot with this pretty easily 
ggplot(data = cl4dat, mapping = aes(x = normalized_effect, y = -log10(p_value))) + 
  geom_point() +
  geom_point(aes(color = (abs(normalized_effect) > 2 & p_value < 1e-20))) +
  geom_text(data = cl4dat %>% filter(abs(normalized_effect) > 2 & p_value < 1e-20),
            aes(x = normalized_effect, y = -log10(p_value) + 3, label = V2), size = 2,) +
  theme_classic() +
  theme(legend.position = "none") +
  scale_color_manual(values = c("darkgray", "darkblue")) +
  labs(title = "Muscle cells", y = expression(-log[10]("p-value")), x = expression(log[2]("fold change")))



#Do the same for cluster 1 (gonad)
cds_cl1 <- cds[,colData(cds)$cluster == 1]
plot_cells(cds_cl1, color_cells_by = "Timepoint")
#DE analysis
#Normalized_effect is equal to log2FC
gene_fits <- fit_models(cds_cl1, model_formula_str = "~Timepoint")
fit_coefs <- coefficient_table(gene_fits)
cl1dat <- fit_coefs %>%
  filter(normalized_effect != 0 ) %>%
  arrange(q_value) %>%
  filter(q_value < 0.05) 
#Should be able to make a volcano plot with this pretty easily 
ggplot(data = cl1dat, mapping = aes(x = normalized_effect, y = -log10(p_value))) + 
  geom_point() +
  geom_point(aes(color = (abs(normalized_effect) > 2 & p_value < 1e-20))) +
  geom_text(data = cl1dat %>% filter(abs(normalized_effect) > 2.7 & p_value < 1e-20),
            aes(x = normalized_effect, y = -log10(p_value) + 3, label = V2), size = 2,) +
  theme_classic() +
  theme(legend.position = "none") +
  scale_color_manual(values = c("darkgray", "darkblue")) +
  labs(title = "Gonad cells", y = expression(-log[10]("p-value")), x = expression(log[2]("fold change")))


#And cluster 13 (neurons)
cds_cl13 <- cds[,colData(cds)$cluster == 13]
plot_cells(cds_cl13, color_cells_by = "Timepoint")
#DE analysis
#Normalized_effect is equal to log2FC
gene_fits <- fit_models(cds_cl13, model_formula_str = "~Timepoint")
fit_coefs <- coefficient_table(gene_fits)
cl13dat <- fit_coefs %>%
  filter(normalized_effect != 0 ) %>%
  arrange(q_value) %>%
  filter(q_value < 0.05) 
#Should be able to make a volcano plot with this pretty easily 
ggplot(data = cl13dat, mapping = aes(x = normalized_effect, y = -log10(p_value))) + 
  geom_point() +
  geom_point(aes(color = (abs(normalized_effect) > 2 & p_value < 1e-20))) +
  geom_text(data = cl13dat %>% filter(abs(normalized_effect) > 2 & p_value < 1e-20),
            aes(x = normalized_effect, y = -log10(p_value) + 3, label = V2), size = 2,) +
  theme_classic() +
  theme(legend.position = "none") +
  scale_color_manual(values = c("darkgray", "darkblue")) +
  labs(title = "Neurons", y = expression(-log[10]("p-value")), x = expression(log[2]("fold change")))


#make an upset plot
upsetdata <- list("Muscle" = cl4dat$V2[1:500], "Gonad" = cl1dat$V2[1:500], "Neurons" = cl13dat$V2[1:500])
upset(fromList(upsetdata), order.by = "freq")

#Find genes that are co-differentially expressed between the three DE analyses
common_elements <- Reduce(intersect, list(cl4dat$V2[1:500], cl1dat$V2[1:500], cl13dat$V2[1:500]))


#Hand off all these genes to Etta for GO analysis
write.csv(cl4dat$V2, "cl4.csv", row.names = FALSE, quote = FALSE)
write.csv(cl1dat$V2, "cl1.csv", row.names = FALSE, quote = FALSE)
write.csv(cl13dat$V2, "cl13.csv", row.names = FALSE, quote = FALSE)
write.csv(common_elements, "DE_allthree_2.csv", row.names = FALSE, quote = FALSE)


