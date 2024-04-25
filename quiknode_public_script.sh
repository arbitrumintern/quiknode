
start_block=62106205
end_block=67303262


current_interval=20
max_retries=6


rpc_url="https://<name>.nova-mainnet.quiknode.pro/<data>/"


output_dir=""
mkdir -p "$output_dir"


for (( block=$start_block; block<=$end_block; ))
do
  success=false

  
  for (( retry=1; retry<=max_retries; retry++ ))
  do
    echo "Trying block range from $block to $(($block+current_interval-1)), attempt $retry with interval $current_interval..."
    output_file="${output_dir}/block_${block}_to_$(($block+current_interval-1)).csv"
   
    if cryo geth_state_diffs -b $block:+$current_interval --requests-per-second 50 --max-concurrent-requests 200 --initial-backoff 2000 --max-retries 10 --max-concurrent-chunks 1 --rpc $rpc_url --csv > "$output_file"
    then
      echo "Successfully processed block range from $block to $(($block+current_interval-1))."
      success=true
      break  
    else
      echo "Attempt $retry failed for block range $block to $(($block+current_interval-1)), retrying..."
      rm "$output_file"  
    fi
  done

  if ! $success && [[ $current_interval -eq 1 ]]; then
    echo "Failed to process block range from $block to $(($block+current_interval-1)) after $max_retries retries, cautiously skipping..."
    block=$(($block + 1))  
    continue  
  fi

  
  if $success; then
    block=$(($block + current_interval))  
    case $current_interval in
      1) current_interval=5;;  
      5) current_interval=10;;  
      10) current_interval=20;; 
    esac
  else
    
    case $current_interval in
      20) current_interval=10;;
      10) current_interval=5;;
      5) current_interval=1;;   
    esac
  fi
done

echo "Completed processing blocks from $start_block to $end_block."
