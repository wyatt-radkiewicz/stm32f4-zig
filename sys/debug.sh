if [[ $# != 4 ]]; then
    echo "usage"
    echo "\t$0 <openocd> <gdb> <elf> <out>"
    exit
fi

interface="interface/stlink.cfg"
board="board/stm32f4discovery.cfg"
openocd_cmds="gdb_port pipe; init; program \\\"$3\\\" preverify verify; reset halt;"
gdb_cmds="target extended-remote | $1 -f $interface -f $board -c \\\"$openocd_cmds\\\""
echo "#!/bin/bash\n$2 -q $3 -ex \"$gdb_cmds\"\n$cleanup" > $4
chmod +x $4
