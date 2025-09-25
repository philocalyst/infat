tag=${GITHUB_REF##*/}
if [[ "$tag" =~ -(alpha|beta)$ ]]; then
  echo "value=true" >> $GITHUB_OUTPUT
else
  echo "value=false" >> $GITHUB_OUTPUT
fi
