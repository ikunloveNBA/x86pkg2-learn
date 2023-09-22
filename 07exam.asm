jmp near start

postive db 'p',0x07,'o',0x07,'s',0x07,'n',0x07,':',0x07                      ;提前占据数据区
postresult dw 0
negative db 'n',0x07,'e',0x07,'g',0x07,'n',0x07,':',0x07
negaresult dw 0
data1 db 0x05,0xff,0x80,0xf0,0x97,0x30
data2 dw 0x90,0xfff0,0xa0,0x1235,0x2f,0xc0,0xc5bc

start:

mov ax,0x7c0
mov ds,ax

mov ax,0xb800
mov es,ax

cld
mov si,postive                            ;传送posn：到显存，posn显示正数
mov di,0
mov cx,(negative-postive)/2
rep movsw

cld
mov si,negative                           ;传送negn：到显存，negn显示负数
mov di,negative-postive
mov cx,(data1-negative)/2
rep movsw

xor ax,ax                                 ;清空ax，将它保存正负数的个数
mov bx,data1
mov si,0
xor dx,dx                                 ;清空dx存放data1中的数据和0比较
mov cx,6

data1cmp:
mov dl,[bx+si]                            ;将data1中的数据保存到dl中，因为data1中用db占位，故用低8位即可
inc si                                    ;si自增指向下一个数据
cmp dl,0 
jg post1                                  ;大于0跳转到post1
jl nega1                                  ;小于0跳转到post2
cmp1:
loop data1cmp                             ;循环6次
jmp data1cmpover

post1:
inc ah                                    ;ah存放正数个数，正数个数+1
jmp cmp1                                  

nega1:
inc al
jmp cmp1

data1cmpover:

mov bx,data2
mov si,0
xor dx,dx
mov cx,7

data2cmp:
mov dx,[bx+si]
add si,2                                  ;因为data2用dw占数据区，所以si+2指向下一个字
cmp dx,0
jg post2
jl nega2
cmp2:
loop data2cmp
jmp data2cmpover

post2:
inc ah
jmp cmp2

nega2:
inc al
jmp cmp2

data2cmpover:

add ax,0x3030                              ;ah和al分别增加0x30变为ascii字符

mov di,postresult-postive                  ;将正数个数放到显存的postresult中
mov [es:di],ah
inc di
mov byte [es:di],0x07

mov di,negaresult-postive
mov [es:di],al
inc di
mov byte [es:di],0x07

jmp near $

times 510-($-$$) db 0

db 0x55,0xaa
               
