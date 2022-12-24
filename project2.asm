
;2nd project microprossesors.
;Author Ioannis Ntouvelos 
;AEM:3340
;I had issues implementing the time pseudo generators so i had to go on without it .
;I made the traffic light to change based on a value of bl during a loop . It changes about every 4-5 seconds .
;I generate the cars using a division modulo . I divide the value of cx with 10 and if the modulo is 0 I generate one car.
;So this is standard too. If we change the initial value of the cx we can define how many steps it will take to generate the second car so the 
;scenario changes a bit . 
 

org 100h           
 
        
.code       




mov ax, 0B800h ; set AX to hexadecimal value of B800h.
mov ds,ax ; copy value of AX to DS.
mov dl, 'A' ; set CL to ASCII code of 'A', it is 41h.
mov dh, 00001111b ; set CH to binary value.



mov bx, 45Eh ; set BX to 15Eh 

mov cx,80   ; we want to print 80 A's to create the first line  


call print_line  
    
                        
mov bx,6DEh    ; print the second line of As
mov cx,80  
call print_line   



mov bx,5E8h      ;print the traffic light 
mov dl,'C'
mov [bx],dx


mov bx,5A0h       ; move bx on the start of the line that the cars move

call generate_car ; we create the first car    

call print_square_green   ; we print the initial light colour


 


mov cx,102 ; the amount of movements that the program will do 

for15:    
    
    push cx               ; we push cx on stack because we will use it after and we want to keep the amount of loops that we will do 
    call move_cars
    pop cx   
    ;here we implement a division so we can generate cars on specific rate.Everytime cx modulo 10 equals zero we generate a car. So basically every 10 steps.
    push ax
    push bx 
    push dx
    mov ax ,cx
    mov bx,10  
    xor dx,dx
    div bx
    cmp dx,0
    je label200
    jmp exit3
    
    
    label200:
    je generate
    jmp exit3
    
    
    generate:      
        mov bx,5A0h
        call generate_car
    
    exit3:   
    pop dx
    pop bx
    pop ax 
    loop for15





ret     


;procedure that prints a line full of the same character at position defined at bx 
; and character and color defined at dx

proc print_line
    for1:
    add bx,2
    mov [bx],dx
    loop for1 
    ret 

;procedure that prints a car where bx points 
proc generate_car  
    
    push cx
    mov cx,4 
    mov dl,'B'
    for2:
    mov [bx],dx  
    add bx,2
    loop for2 
    pop cx
    ret      
    



;procedure that implements the move of all cars and changes the colour of the light based on a value .
;we check every character in the line that the cars move.
;if we find a car (B character) we make the following checks : 
;1- We check if the car has reached a traffic light (C character).If it has, we check light's colour and make the appropiate action.
;2- We check if the car has reached the end of the line. If it has we delete it otherwise we keep going. 
;We make all these checks for every car we find during the search.
proc move_cars
    
    mov bx,5A0h  
    
    mov cx,500
    
    
    
    formove:   
    
          
        cmp bl,06h      ; check for changing the light , pseudo time geneator ( kinda ) , just changing it every time bl takes a specific value during the loop.
        je changelight
        jmp nolightchange 
        
       
    
        changelight:    ; we push bx and dx to the stack because we will change their values when we will change light
             push bx
             push dx
             call change_light    
             pop dx
             pop bx
         
    
        nolightchange:
    
            cmp [bx],'B'  ; check if we found a car 
            je foundcar
            jmp exit
            
            foundcar:  
                 add bx,8         ; we add 8 to reach one character after the end of the car , 4*2bytes for each character and colour
                 cmp [bx],'C'     ; check if the end of the car is at the traffic light
                je trafficlightahead 
                
                cmp [bx],'B'      ;we check if we have a car in front to avoid bumping we dont make a move for this specific car.
                je exit2
                
                ; if we are not at a traffic light we just move the car 
                add bx,8     ; we add 8 because every move of the car is one full car length ahead , so we have to check a full car ahead if we reach the end
                cmp bx,63Eh  ; check if the move of the car will reach the end of the line 
                jge reachedend 
                add bx,-16    ; we subtract 16 to reach back at the start of the car and complete its move 
                call delete_car
                call generate_car
                jmp exit  
             
             ; if we are at a traffic light we check what color it is 
            trafficlightahead:
                 cmp al,1h    ; al keeps the value of the colour of the traffic light , 1 is green 0 is red
                 je movecar  ;if it is green we move the car 
                 jmp exit ; if it is red we just continue the loop  
             
             
            movecar:
                 add bx,-8   ; we subtract the 8 we had added to check for the light ahead and reached the start of the car.
                 call delete_car   ; we delete the car
                 add bx,2           ; we move the pointer 1 step ahead
                 call generate_car  ; we generate the car there.
                 
             
               
                
            exit:
                add bx,2
                cmp bx,63Eh  ;this check is for the bx value to see if we reached the end of the line , if we have that means we made all the moves for the cars in the line.
                je procend 
                jmp exit2     ;if we haven't we just continue on the loop 
              
              
                         
            reachedend:       ; if it does reach the end of line we just delete it
                add bx,-16 
                call delete_car 
                jmp procend
              
            procend: 
                ret
            exit2:
            
    
     loop formove
ret
        



;procedure that based on the value of al , that keeps the value of the colour of the traffic light , 1 is green 0 is red
;decides what colour we gonna make the light and we call the appropiate procedure     
proc change_light
    cmp al,1
    je turn_red
    jmp exit4
    
    
    turn_red:
      call print_square_red 
      ret
    
    exit4: 
      call print_square_green
      ret
            
            
        
        
;procedure that deletes the car , when we call it we need bx to point at the start of the car        
proc delete_car  
    push cx
     mov cx,4
     
     for20:
     
        mov dl,' '            ; delete a B
        mov dh,00001111b
        mov [bx],dx 
        add bx,2 
        
        loop for20
        
     pop cx
        
     ret
       
       
       
       
;procedure that makes the traffic light red.
;we make the foreground of the 3 top right rows red.        
;we change al to 0 to know that the light is red now.        
proc print_square_red 
    push cx 
    mov cx,5 
    mov dl,' '
    mov dh,01000000b
    mov bx,96h
    
    for4:
    mov [bx],dx     
    add bx,2 
    loop for4    
    
    mov bx,136h 
    
    
    mov cx,5
    
    for5:
    mov [bx],dx     
    add bx,2 
    loop for5 
    
    mov bx,1D6h 
    
    
    mov cx,5
    
    for6:
    mov [bx],dx     
    add bx,2 
    loop for6  
    
    
    mov al,0h  
    pop cx
     
    ret
    
    
;procedure that makes the traffic light green.
;we make the foreground of the 3 top right rows green. 
;we change al to 1 to know that the light is green now.    
 proc print_square_green 
    push cx
    mov cx,5 
    mov dl,' '
    mov dh,00100000b
    mov bx,96h
    
    for7:
    mov [bx],dx     
    add bx,2 
    loop for7    
    
    mov bx,136h 
    
    
    mov cx,5
    
    for8:
    mov [bx],dx     
    add bx,2 
    loop for8 
    
    mov bx,1D6h 
    
    
    mov cx,5
    
    for9:
    mov [bx],dx     
    add bx,2 
    loop for9 
    
    
    mov al,1h 
   pop cx
     
    ret   
    
    
    
    
    
    
    
    
    
    
            
        
        
        