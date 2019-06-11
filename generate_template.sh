#!/bin/bash 

if mkdir $1; then 
    cp common/template/* $1/
else 
    echo "Directory $1 already exists"
fi 

 


