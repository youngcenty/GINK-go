library(data.table)
library(depmixS4)

setwd('./')
lf = list.files(pattern = '*.trk')
filename = gsub('.trk','',lf)
for (i in seq_along(lf)){
  track0.df <- read.csv(lf[i],col.names =c('x','y','Intensity','Time','HMMStates'), sep = '\t')
  dt <- data.frame(Time=double(), Intensity=double(), HMMStates=double())
  
  # Set the seed so that we get deterministic fit everytime we run this
  set.seed(1000)
  # FIX the number of HMM states to 3
  hmm <- depmix(Intensity ~ 1, family = gaussian(), nstates = 2, data=track0.df)
  val <- "Yes"
  # Optimize the HMM using EM
  val <- tryCatch(hmmfit <- fit(hmm, verbose = FALSE), error=function(e) "No")
  
  if(class(val) == "depmix.fitted") {
    # Get the posterior probability
    post_probs <- posterior(hmmfit)
    # Save the density estimates to identify ON/OFF (2/1) state.
    onoffestimates <- summary(hmmfit)
    # Let's make sure that state 1 is always off and state 2 is on
    post_probs$modstate <- post_probs$state
    legStr <- c("Off", "On")
    if (onoffestimates['St1', 1] > onoffestimates['St2', 1])
    {
      post_probs$modstate[post_probs$state == 1] <- 2
      post_probs$modstate[post_probs$state == 2] <- 1
      legStr <- c("On", "Off")
    }
    dt <- data.frame(Time=track0.df$"Time", Intensity=track0.df$"Intensity", HMMStates=post_probs$modstate)
  }
  # Return Interval Histogram
  write.table(dt, file = paste(filename[i],'_hmm2states.trk',sep = ""), sep = '\t', row.names = FALSE)
}

