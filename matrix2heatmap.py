#!/usr/bin/env python3
import numpy as np
import matplotlib.pyplot as plt
import sys
import argparse
import re

# parse input options
parser = argparse.ArgumentParser(prog="matrix2heatmap.py",
								description="read the HiC link matrix of HiC-Pro output and draw contact heatmap among contig bins in PDF format",
								epilog="Author: Sen Wang, wangsen1993@163.com, 2021/9/2")
parser.add_argument("bed", type=str, help="positions of contig bins in BED format")
parser.add_argument("matrix", type=str, help="link matrix among bins")
args = parser.parse_args(sys.argv[1:])

# read and link bin number and contig id
gp = re.search(r'_(\d+)', args.matrix)
size = int(gp.group(1))
binsize = ""
if size // 1000000000 > 0:
	binsize = str(size // 1000000000) + "G"
elif size // 1000000 > 0:
	binsize = str(size // 1000000) + "M"
elif size // 1000 > 0:
	binsize = str(size // 1000) + "K"

ctg2bin = {}
bins = []
with open(args.bed, "r") as f:
	for line in f:
		t = line.strip().split("\t")
		ctg2bin[t[0]] = t[3]
		bins.append(t[3])

bin2ctg = {}
for k,v in ctg2bin.items():
	v = int(bins.index(v)) + 1
	bin2ctg[v] = k

# read link matrix
binmx = [[0 for i in bins] for j in bins]
with open(args.matrix, "r") as f:
	for line in f:
		t = line.strip().split("\t")
		if t[0] in bins and t[1] in bins:
			binmx[bins.index(t[0])][bins.index(t[1])] = t[2]
			binmx[bins.index(t[1])][bins.index(t[0])] = t[2]
		else:
			continue

# draw heatmap
binmx = np.asarray(binmx, dtype=float)
size = len(bins) / 72;
if size < 5:
	size = 5
plt.figure(1, figsize=(size * 1.365, size * 1.1))
plt.imshow(np.log2(binmx+1), cmap="YlOrRd", aspect="auto", interpolation="none", origin="lower")
plt.colorbar(location="right", orientation="vertical", shrink=0.5)
plt.title(binsize + " per bin")
pos = 0
for i in sorted(bin2ctg.keys()):
	plt.axvline(x=int(i) - 0.5, ls="-", lw=0.1, color="black")
	plt.axhline(y=int(i) - 0.5, ls="-", lw=0.1, color="black")
	plt.text((pos + int(i)) / 2, 0, bin2ctg[i] + " ", fontsize=8, horizontalalignment="center", verticalalignment="top", rotation="vertical")
	plt.text(0, (pos + int(i)) / 2, bin2ctg[i] + " ", fontsize=8, horizontalalignment="right", verticalalignment="center")
	pos = i

plt.xticks(ticks=[])
plt.yticks(ticks=[])
ax = plt.gca()
ax.spines['left'].set_linewidth(0.1)
ax.spines['bottom'].set_linewidth(0.1)
ax.spines['right'].set_visible(False)
ax.spines['top'].set_visible(False)
plt.savefig(args.bed + ".pdf", bbox_inches="tight")
