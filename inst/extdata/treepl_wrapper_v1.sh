#!/bin/bash
# version: 1.0 - macOS-compatible treePL wrapper

# Usage check
if [ $# -ne 3 ]; then
    echo -e "Error: incorrect usage"
    echo -e "Usage:\n$0 configuration treefile label"
    exit 1
fi

CONFIG_FILE="$1"
TREE_FILE="$2"
LABEL="$3"

# Check if the config and tree files exist
if [ ! -f "$CONFIG_FILE" ] || [ ! -f "$TREE_FILE" ]; then
    echo -e "Error: can't find the files"
    echo -e "Usage:\n$0 configuration treefile label"
    exit 2
fi

echo -e "================================================================"
date
echo -e "$0 $CONFIG_FILE $TREE_FILE $LABEL"
echo -e "Start running, good luck!"
echo -e "================================================================"

# Step 1: Generate prime config file
echo "Step 1: generate the prime config file"

{
    echo "treefile = $TREE_FILE"
    cat "$CONFIG_FILE"
    echo -e "thorough\nprime"
} > configure_prime_"$LABEL"

# Step 2: Run primes 100 times
echo "Step 2: run primes 100 times"

> prime_"$LABEL"
for num in $(seq 100); do
    treePL configure_prime_"$LABEL" |\
    sed -n '/^opt/,$p' |\
    sed 's/.*\(.\)/\1/' |\
    tr '\n' ' ' >> prime_"$LABEL"
    echo >> prime_"$LABEL"
done

# Step 3: Generate CV config
echo "Step 3: generate the CV config file"

sed 's/^prime/#&/' configure_prime_"$LABEL" |\
awk '{print} END {print "cv\ncvoutfile = cv_'$LABEL'\ncvstart = 0.0001\ncvstop = 10000"}' \
> configure_cv_"$LABEL"

# Step 4: Choose most frequent prime result
echo "Step 4: choose the most frequent CV optimal parameters"

sort prime_"$LABEL" | uniq -c | sort -nr | head -n 1 | sed 's/^[ \t]*//' |\
awk '{if($3 != "l") $2=$2" o"; print}' |\
awk '{if($5 != "d") $4=$4" o"; print}' |\
awk '{if($7 != "d") $6=$6" o"; print}' |\
sed 's/ /\n/g' | sed '1d' | sed 's/o/#/g' |\
sed '1s/^/opt = &/' |\
sed '2s/l/moredetail/' |\
sed '3s/^/optad = &/' |\
sed '4s/d/moredetailad/' |\
sed '5s/^/optcvad = &/' |\
sed '6s/d/moredetailcvad/' \
>> configure_cv_"$LABEL"

# Step 5: Run CV
echo "Step 5: perform cross-validation (this may take a while)"
treePL configure_cv_"$LABEL" > cv_"$LABEL".log 2>&1

if [ ! -f cv_"$LABEL" ]; then
    echo "Error: cross-validation failed"
    exit 3
fi

# Step 6: Generate smoothing config
echo "Step 6: generate the smooth config file"

sed 's/^cv/#&/' configure_cv_"$LABEL" |\
awk '{print} END {print "outfile = treepl_'$LABEL'.tre"}' \
> configure_smooth_"$LABEL"

# Step 7: Extract smoothing value
echo "Step 7: find the smallest CV score"

awk '{printf "%f\t%s\n", $3, $2}' cv_"$LABEL" |\
sort -n | head -n 1 | awk '{print $2}' |\
sed 's/[()]//g;s/^/smoothing = /' \
>> configure_smooth_"$LABEL"

# Step 8: Final treePL run
echo "Step 8: final run"

treePL configure_smooth_"$LABEL" > final_"$LABEL".log 2>&1


echo -e "================================================================"
echo -e "Finished. Check 'treepl_${LABEL}.tre' for the result."
date
echo -e "================================================================"

exit 0