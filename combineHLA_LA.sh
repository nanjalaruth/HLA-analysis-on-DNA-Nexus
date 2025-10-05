#Extract column 3 
cut -f 3 R1_bestguess_G.txt > test

#Transpose column to row
tr "\n" "\t" < test > test1

#remove 1st column
cut -f 2-17 test1 > test2

#add 0 for the first 4 columns
for i in {1..4}; do sed -i 's/^/0\t/' test2 ; done

#add the sample name column twice
for i in {1..4}; do sed -i 's/^/"${dataset}"\t/' test3 ; done 

# Combine the output
cat test3 >> MXL_sample_1.hped

# Combine all the ped files
cat *.ped | \
    sed '1 i FID\\tIID\\tPID\\tMID\\tSEX\\tPHENO\\tA.1\\tA.2\\tB.1\\tB.2\\tC.1\\tC.2\\tDQA1.1\\tDQA1.2\\tDQB1.1\\tDQB1.2\\tDRB1.1\\tDRB1.2\\tDPA1.1\\tDPA1.2\\tDPB1.1\\tDPB1.2\\tDRB3.1\\tDRB3.2\\tDRB4.1\\tDRB4.2\\tE.1\\tE.2\\tF.1\\tF.2\\tG.1\\tG.2\\tPop' > MXL.hped
	
