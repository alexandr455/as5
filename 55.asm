.model small
.stack 100h       

.data  
   
equal db "Files are equal.",'$'
nEqual db "Files aren't equal.",'$'

fopenError db 09h,"An error occurred while opening file: ",'$' 
freadError db 09h,"An error occurred while reading file: ",'$'
cmdError db 09h,"Could't get file names from cmd arguments",'$'
fileNotFound db "file not found.",'$'
pathNotFound db "path not found.",'$'
2ManyFiles db "too many files opened.",'$'
accessDenied db "access denied.",'$'
invalidAccessMode db "invalid access mode.",'$' 
sizeNEqual db "File sizes aren't equal.",'$'
wrongHandle db "wrong handle.",'$'  

firstFileName db 126 dup(0)
secondFileName db 126 dup(0)

buf1 db 0
buf2 db 0 

readLEN dw 1                   
firstFile dw 0
secondFile dw 0

.code
jmp main 

;������ readLen �������� �� file � buf
readFile MACRO file, buf  
    mov bx, file ;������������� �����
    mov cx, readLEN ;����� ���� ��� ������
    mov dx, offset buf  ;����� ������ ��� ����� ������
    mov ah, 3Fh  ;������ �� �����
    int 21h    
ENDM     
 
;����� ��������� ������
resetFile MACRO file  
    xor cx, cx
    xor dx, dx   ; ����������, �� ������� ���� �����������
    mov bx, file ; ������������� �����
    mov al, 00h  ;����������� ������������ ������
    mov ah, 42h  ;����������� ��������� ������/������
    int 21h      
ENDM        
 
;��������� ������� ����� 
getSize MACRO file  
    xor cx, cx
    xor dx, dx 
    mov bx, file   ; ����������, �� ������� ���� �����������                                  
    mov al, 02h    ; ������������� �����                                                      
    mov ah, 42h    ; ����������� ������������ ����� �����                                           
    int 21h        ; ����������� ��������� ������/������                                       
ENDM                                                                                          

;�������� �����
closeFile MACRO file  
    mov bx, file ; ������������� ����� 
    mov ah, 3Eh ; �������� �����
    int 21h      
ENDM

;����� ������ �� �����
outputString MACRO string
    push ax
    mov dx, offset string
    mov ah, 09h
    int 21h      
    pop ax
ENDM 

;������� �������� � ������ str
skipSpaces MACRO str  
    LOCAL skip
    sub str, 1
    skip:
    inc str
    cmp [str], ' ' 
    je skip
ENDM

;����������� �� si � string �� ������� ��� ����� ��������� ������
copyWord MACRO string
    LOCAL copy
    mov di, offset string
    
    copy:
    movsb
    
    cmp [si], 0Dh           ;������� ����� ��������� ������
    je cmdEnd
    
    cmp [si], ' '
    jne copy
       
ENDM 

;��������� ���� ���� �� ��������� ������
getFileNames proc
    pusha
		
	mov si, 82h             ;������ ��������� ������ 
	
    skipSpaces si           ;������� ��������
	
	copyWord firstFileName      ;���������� ������� �����
	
	skipSpaces si           ;������� ��������
	
	copyWord secondFileName      ;���������� ������� �����
	
	cmdEnd:	    
    popa
    ret
endp

;����� ���������� ������ ����� ������
resetFiles proc
    pusha    
    resetFile firstFile 
    resetFile secondFile  
    popa
    ret
endp
 
;������� ���� � ������ ������ ������ 
openFileR proc 
    xor cx, cx 
    xor al, al
    mov ah, 3dh  ;�������� ������������� �����
    mov al, 00h  ;������� ��� ������
    int 21h 
    jc openFail  ;�������� �� �������� ����� 
    ret    
endp  

;��������� ������ �� ��������
cmpSize proc 
    pusha
    
    getSize firstFile       ;�������� ������ ������� �����
    
    ;��������� �������� � ����
    push ax
    push dx 
    
    getSize secondFile      ;�������� ������ ������� �����
    
    ;����������� �������� � ������ ���� ���������
    mov cx, ax
    mov bx, dx 
    
    ;������� ������ ������� �����
    pop dx
    pop ax
    
    ;�������� ������ 1 � 2 �����
    cmp ax, cx
    jne sizeNotEqual 
    cmp bx, dx
    jne sizeNotEqual        
            
    popa
    ret             
    
    sizeNotEqual:
    popa
    jmp sizeExit
endp 
 
;��������� ����� �� ����������� 
cmpFiles proc 
    
    call resetFiles 
    
    comparing:
        
        readFile firstFile, buf1    ;��������� ������ �� 1 �����
        jc failedReading
        ;��������� 0 �������� - ����� �����
        cmp ax, 0
        je eof            
        
       
        readFile secondFile, buf2   ;��������� ������ �� 2 �����
        jc failedReading
    
    ;��������� �������� 
    ;;;;;;;;;;;;;;;;   
    ;mov bl, buf1
    ;cmp bl, buf2  
    ;pusha
    mov si, offset buf1
    mov di, offset buf2 
    mov cx , 1
    cld
    repe  cmpsb
    je comparing          
    
    ;popa 
    ;;;;;;;;;;;;;;;;;
    
    ;je comparing
    
    jmp notEqual 
    
    eof:
    ret
endp   

;�������� ���������� 2 ��� ������ �� ��������� ������
checkNames proc    
    
    cmp [firstFilename], 0
    je namesNotFound
    
    cmp [secondFilename], 0
    je namesNotFound
    
    ret
endp



main:
    mov ax, @data 
    mov es, ax 
    
    ;��������� ��� ������ �� cmd
    call getFileNames
    
    mov ds, ax  
    
    ;�������� ��������� ��� ������
    call checkNames   
    
    ;������� ������ ����
    mov dx, offset firstFileName
    call openFileR
    mov firstFile, ax 
                  
    ;������� ������ ����                 
    mov dx, offset secondFileName
    call openFileR
    mov secondFile, ax
     
    ;�������� ����� �� �������� 
    call cmpSize    
    
    ;�������� ����� �� �����������
    call cmpFiles   
    
    ;����� �����
    outputString equal
    
    jmp closeFiles

;������ ��� �������� �����
openFail:
    
    outputString fopenError         
    
    ;���� �� ������
    cmp ax, 02h   
    jne not2
    outputString fileNotFound
    jmp closeFiles     
    
not2: 
    ;���� �� ������ 
    cmp ax, 03h 
    jne not3  
    outputString pathNotFound
    jmp closeFiles      
    
not3:  
    ;������� ������� ����� ������
    cmp ax, 04h
    jne not4   
    outputString 2ManyFiles
    jmp closeFiles
    
not4:
    ;�������� � �������
    cmp ax, 05h
    jne not5 
    outputString accessDenied
    jmp closeFiles      
    
not5: 
    ;������������ ����� �������
    outputString invalidAccessMode
           
;�������� ������           
closeFiles:    
    closeFile firstFile                
    closeFile secondFile 

exit:
    ;���������� ������
    mov ah, 4Ch
    int 21h 

;������ �������    
sizeExit: 
    outputString sizeNEqual
    jmp closeFiles 

;����� �� �����    
notEqual:
    outputString nEqual
    jmp closeFiles 

;������ ��� ������    
failedReading: 

    outputString freadError
    cmp ax, 05h
    jne skip 
    
    ;�������� � ������� 
    outputString accessDenied
    jmp closeFiles
     
    skip: 
    ;������������ �������������
    outputString wrongHandle
    jmp closeFiles
    
namesNotFound:
    outputString cmdError
    jmp exit
    
end main