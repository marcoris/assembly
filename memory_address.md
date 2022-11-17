[< Back](README.md)

## Memory address
The processor looks to the last **six** bytes of memory - addresses `$fffa` to `$ffff` - to find the memory address of where each
handler begins.

| Memory address  | Use                    |
|-----------------|------------------------|
| `$fffa - $fffb` | Start of NMI handler   |
| `$fffc - $fffd` | Start of reset handler |
| `$fffe - $ffff` | Start of IRQ handler   |

Because these six bytes of memory are so important, ca65 has a specific segment type for them: .segment "VECTORS". The 
most common way to use this segment is to give it a list of three labels, which ca65 will convert to addresses when 
assembling your code. Here is what our test project's "VECTORS" segment looks like:

````asm
.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler
````
