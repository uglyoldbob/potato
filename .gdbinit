disp /i $eip
set args "stage1/main.p0" "build/stage1/main.o"
set disassembly-flavor intel

define memory_region
 echo Memory regions:\n
 set $block = (int)&start_dynamic_allocation
 set $i = 1
 set $amount = 0
 printf "Total memory: %d\n", *(int)&total_space
 print /x $block
 set $block = *$block
 while $block != 0
 printf "Block %d: 0x%x\n", $i, $block
 printf "\tPrev: 0x%x\n", *$block
 printf "\tNext: 0x%x\n", *($block+4)
 printf "\tAddr: 0x%x\n", *($block+8)
 printf "\tFlags: 0x%x\n", *($block+12)
 printf "\tSize: %d\n", *($block+16)
 set $amount = $amount + *($block+16) + 20
 set $block = *($block+4)
 set $i = $i + 1
 end
 printf "Total bytes in sections: %d\n", $amount
 if $amount == *(int)&total_space
  printf "Memory amounts match\n"
 else
  printf "MEMORY AMOUNTS DO NOT MATCH!\n"
 end
end