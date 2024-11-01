
## 11/1 Check In 

##Addressing prior feedback: 


Feedback on our proposal was mostly based on reading deeper to better understand the paper. Some issues brought up were potential crowding of worms at day 15 that might alter expression in ways we are not interested in. By reading deeper into the paper methods, we discovered that the food sources were maintained for the worms over the time course (controlling for starvation-based expression changes), and that the worms used had a mutation that prevented gonad development and reproduction, preventing overcrowding of the plates (and thus preventing another source of stress-based expression changes). Another bit of feedback was to make sure we pay attention to normalization procedures. In this regard, we plan to use Monocle3 normalization methods for our scRNASeq data. I also noted that the dataset was available having already been processed with the 10X Genomics Cell Ranger pipeline. 

##New Progress since Last Submission: 


Since the last submission, we have successfully installed Monocle3, loaded in the Day1 and Day15 data sets, normalized with PCA (100 principle components were shown to be more than enough to explain the majority of the variance within the expression dataset), reduced dimensionality, and plotted the cells from both time points with UMAP. We intended to move on to clustering by cell type, and then differential expression of our tissues of interest (neurons, muscle, and epithelium). However, we ran into some problems with the dataset that need to be addressed before this can be done. 


##Project Organization: 

Before we can create a volcano plot/upset plot, some issues with the dataset need to be addressed, and potentially different timepoints must be selected. More info on this is described below. 


##Struggles/Questions: 

The most significant problem we've encountered is that the day 15 timepoint has far fewer cells (~800) than day 1 (~10,000). This likely makes any kind of differential expression analysis between these datasets heavily affected by cell type underrepresentation. Indeed, when plotted via UMAP, you can clearly see that only a small subset of the clusters are represented in the day 15 sample (see Initial_UMAP.png. Sample1 is the day 1 timepoint, sample 2 is the day15 timepoint). Differential expression across all tissue types would be heavily biased in this case as so many cell types are underrepresented in day 15, and tissue-specific DE analysis might not be possible depending on what tissues types are included in the sample. I think we should switch to a different timepoint for comparison to day 1 (day 3 or day 5 maybe, as these look to represent all the cell types well from the paper). This brings us to a second problem, which is that the data files we downloaded do not include cell type annotations for each entry in the dataset (i.e. we can't annotate clusters by cell type, because those annotations are not included in the raw data files). This is because the authors in the paper assigned cell types by specific marker gene profiles after clustering based on expression. There are two ways we could address this. We could try to recapitulate the author's method of assigning cell types based on marker genes (this would likely be difficult and time intensive). Or, since the authors include a table in the supplemental material that lists the tissue types by cluster, we can go through and manually annotate the clusters in Monocle3 (I think this is what we should do). Once this is done, we can perform the DE analysis as described in our proposal. 