#! /bin/bash

gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=/mnt/billing_401k/combine.pdf /mnt/billing_401k/*.pdf
