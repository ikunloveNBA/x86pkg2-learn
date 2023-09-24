jmp near start                           
data1 db '1+2+3+4+5+...+999+1000='              ;用字符串形式表示1到100的和

start:
mov ax,0x7c0                                  ;数据段基地址
mov ds,ax                                     

mov ax,0xb800                                 ;附加段基地址
mov es,ax

mov si,data1
mov di,0
mov cx,start-data1

dispstring:                                   ;将字符串传送到显存
mov al,[si]
mov [es:di],al                                ;附加寄存器要使用超越段前缀
inc di
mov byte [es:di],0x07
inc si
inc di
loop dispstring

xor ax,ax                                      ;ax保存结果的低16位
xor dx,dx                                      ;dx保存结果的高16位
mov cx,1000

cmpnumber              
add ax,cx
adc dx,0                                       ;adc是进位加法，相当于dx+0+cf                              
loop cmpnumber                                

xor cx,cx                                      ;清空cx，并设置栈段寄存器和栈指针寄存器基地址
mov ss,cx
mov sp,cx

mov bx,10

div1:                                          ;将累加和除以10，并将余数保存到dl中
inc cx
div bx
push dx                                        ;因为栈只允许每次传入一个字，所以传入dx
xor dx,dx
cmp ax,0
jne div1

dispresult:                                    ;将最终结果传送到显存中
pop dx                                         ;弹出栈到dx中，先进后出，后进先出
or dl,0x30
mov [es:di],dl
inc di
mov byte [es:di],0x07
inc di
loop dispresult

jmp near $

times 510-($-$$) db 0
db 0x55,0xaa
