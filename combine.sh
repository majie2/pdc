#! /bin/bash

gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=/mnt/billing_pd/combine.pdf /mnt/billing_pd/Excel/*.pdf
