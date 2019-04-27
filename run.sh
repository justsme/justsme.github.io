#!/bin/bash
git add .
git commit ${1:-'add blog'}
git push
git push coding
hexo g -d
