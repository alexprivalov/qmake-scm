#!/bin/bash

BASEPATH=$(dirname $0)
cp -n $BASEPATH/git_version.txt version.txt
cp -n $BASEPATH/version.in version.in
echo \"version.txt export-subst\" >> .gitattributes
echo "Don't forget to commit changes"