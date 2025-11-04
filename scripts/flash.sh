cmds="init; \
reset halt; \
flash write_image erase $1 0x08000000; \
reset run; \
shutdown;"
openocd -f interface/stlink.cfg -f board/stm32f4discovery.cfg -c "$cmds"
