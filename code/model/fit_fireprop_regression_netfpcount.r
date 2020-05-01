# Rscript fit_fireprop_regression.r DATAFILE OUT_PARAM_FILE

args = commandArgs(trailingOnly=TRUE)
data = read.table(args[1])
out_file = args[2]

colnames(data) = c("L6", "L7", "R6", "R7", "PR6", "PR7", "FL7SUM", "L7MAX", "FCNT", "PCNT")
dat4fit = data.frame(DLT=data$PR7 - data$PR6, FCNT=as.integer(data$FL7SUM/data$L7MAX), PCNT=data$PCNT)
reg = glm(cbind(FCNT, PCNT - FCNT) ~ DLT, data=dat4fit, family=binomial(link="logit"))

coeffs = sprintf("b0=%f\nb1=%f\n", reg$coefficients[[1]], reg$coefficients[[2]])
cat(coeffs, file=out_file)