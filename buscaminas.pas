PROGRAM juego4; { Ejecutar en terminal de 80x25 }

USES crt,dos;

CONST esc = #27; arr=#72; aba=#80; der=#77; izq=#75; ent=#13;

TYPE
 celda = record contenido,estado:byte end;
 terreno = array[1..16,1..30] of celda;

VAR
 campo:terreno;        comienzo:boolean;       accion:char;
 fila,columna,base,altura,minas,libres,b_d_x,b_d_y,nivel_anterior:byte;
 h,m,s,cs,seg,contador,principiante,intermedio,experto:word;

FUNCTION X(jj,b:byte):byte; Begin x:= 2*jj + b End;

FUNCTION Y(ii,b:byte):byte; Begin y:= ii + b End;

PROCEDURE Valores_Iniciales(caracter:char;var seg:word;var longb,longh,x_minas,x_libres,b_x,b_y:byte;var start:boolean);
Begin
 Case caracter of
  '1':begin longb:=9; longh:=9; x_minas:=10; b_x:=30; b_y:=6 end;
  '2':begin longb:=16; longh:=16; x_minas:=40; b_x:=23; b_y:=3 end;
  '3':begin longb:=30; longh:=16; x_minas:=99; b_x:=9; b_y:=3 end
 end;
 x_libres:=longb*longh - x_minas; start:=false; seg:=0
End;

PROCEDURE Inicializo_Matriz(var campus:terreno; longb,longh:byte);
Var i,j:byte;
Begin
 For i:=1 to longh do
  For j:=1 to longb do
   begin campus[i,j].contenido:=0; campus[i,j].estado:=1 end
End;

PROCEDURE Minar_Campo(var campus:terreno; longb,longh,x_minas:byte);
Var i,j,k:byte;
Begin
 For k:=1 to x_minas do
  begin
   Repeat
    i:= Random(longh)+1;
    j:= Random(longb)+1;
   Until campus[i,j].contenido in [0..8];
   campus[i,j].contenido:=9;
   If i-1>0 then
    begin
     If (j-1>0)and(campus[i-1,j-1].contenido<>9) then inc(campus[i-1,j-1].contenido);
     If (j+1<=longb)and(campus[i-1,j+1].contenido<>9) then inc(campus[i-1,j+1].contenido);
     If campus[i-1,j].contenido<>9 then inc(campus[i-1,j].contenido)
    end;
   If i+1<=longh then
    begin
     If (j-1>0)and(campus[i+1,j-1].contenido<>9) then inc(campus[i+1,j-1].contenido);
     If (j+1<=longb)and(campus[i+1,j+1].contenido<>9) then inc(campus[i+1,j+1].contenido);
     If campus[i+1,j].contenido<>9 then inc(campus[i+1,j].contenido);
    end;
   If (j-1>0)and(campus[i,j-1].contenido<>9) then inc(campus[i,j-1].contenido);
   If (j+1<=longb)and(campus[i,j+1].contenido<>9) then inc(campus[i,j+1].contenido)
  end
End;

PROCEDURE Caracter(ff,cc,color:byte);
Begin
Case color of
 red:begin textcolor(red+8); write('[]') end;
 yellow:begin textcolor(color); write('??') end;
 else
  begin
   if (ff+cc) mod 2 = 0 then textcolor(8) else textcolor(7);
   write('[]');
  end
end
End;

PROCEDURE Construye_Campo(var campus:terreno;longb,longh,b_x,b_y:byte);
Var i,x1,x2,y1,y2:byte;
Begin
 x1:= X(1,b_x)-1;  x2:= X(longb,b_x)+2;  y1:=Y(1,b_y)-1;  y2:=Y(longh,b_y)+1;
 textcolor(green);
 For i:=(x1) to (x2) do
  begin gotoxy(i,y1); write('-'); gotoxy(i,y2); write('-') end;
 For i:=(y1+1) to (y2-1) do
  begin gotoxy(x1,i); write('|'); gotoxy(x2,i); write('|') end;
 For i:=1 to longh do
  For x1:=1 to longb do
   begin
    gotoxy(X(x1,b_d_x),Y(i,b_d_y));
    Caracter(i,x1,7)
   end
End;

PROCEDURE Derecha(var campus:terreno; var f,c,xc:byte);
Begin If c < xc then inc(c) else c:=1 End;

PROCEDURE Izquierda(var campus:terreno; var f,c,xc:byte);
Begin If 1 < c then dec(c) else c:= xc End;

PROCEDURE Arriba(var campus:terreno; var f,c,xf:byte);
Begin If 1 < f then dec(f) else f:=xf End;

PROCEDURE Abajo(var campus:terreno; var f,c,xf:byte);
Begin If f < xf then inc(f) else f:=1 End;

PROCEDURE Numero(num:byte);
Begin
 Case num of
  1..6: textcolor(num+8);
     7: textcolor(7);
     8: textcolor(15)
 end;
 write(num:2)
End;

PROCEDURE Libera(var campus:terreno; i,j:byte; var longb,longh,x_libres:byte);
Begin
 dec(x_libres);
 campus[i,j].estado:=0; gotoxy(X(j,b_d_x),Y(i,b_d_y));
 If campus[i,j].contenido <> 0 then Numero(campus[i,j].contenido)
 else
  begin
   write('  ');
   If(0<j-1)and(campus[i,j-1].estado in[1,3])then Libera(campus,i,j-1,longb,longh,x_libres);
   If(j+1<=longb)and(campus[i,j+1].estado in[1,3])then Libera(campus,i,j+1,longb,longh,x_libres);
   If(i+1<=longh)and(campus[i+1,j].estado in[1,3])then Libera(campus,i+1,j,longb,longh,x_libres);
   If(0<i-1)and(campus[i-1,j].estado in[1,3])then Libera(campus,i-1,j,longb,longh,x_libres);
   If(0<j-1)and(0<i-1)and(campus[i-1,j-1].estado in[1,3])then Libera(campus,i-1,j-1,longb,longh,x_libres);
   If(0<j-1)and(i+1<=longh)and(campus[i+1,j-1].estado in[1,3])then Libera(campus,i+1,j-1,longb,longh,x_libres);
   If(j+1<=longb)and(0<i-1)and(campus[i-1,j+1].estado in[1,3])then Libera(campus,i-1,j+1,longb,longh,x_libres);
   If(j+1<=longb)and(i+1<=longh)and(campus[i+1,j+1].estado in[1,3])then Libera(campus,i+1,j+1,longb,longh,x_libres)
  end
End;

PROCEDURE Record_(bx,matiz:byte; p,i,e:word);
Begin
 textcolor(red + matiz*8);
 Case bx of
  30:begin gotoxy(21,23); write(p:5) end;
  23:begin gotoxy(21,24); write(i:5) end;
   9:begin gotoxy(21,25); write(e:5) end
 end
End;

PROCEDURE Reescribe(b_x,tono:byte; facil,medio,dificil:word);
Begin
 textcolor(7 + tono*8);
 Case b_x of
  30:begin gotoxy(1,23); write('[1] Principiante') end;
  23:begin gotoxy(1,24); write('[2] Intermedio') end;
   9:begin gotoxy(1,25); write('[3] Experto') end
 end;
 Record_(b_x,tono,facil,medio,dificil)
End;

PROCEDURE New_Record(b_x:byte; var seg,facil,medio,dificil:word);
Var cambie:boolean;
Begin
 cambie:=false;
 Case b_x of
  30: If seg < facil then begin cambie:=true; facil:=seg end;
  23: If seg < medio then begin cambie:=true; medio:=seg end;
   9: if seg < dificil then begin cambie:=true; dificil:=seg end
 end;
 If cambie then Record_(b_x,1,facil,medio,dificil)
End;

PROCEDURE Texto_Centrado(texto:string; lin,color:byte);
Begin gotoxy(41 - (length(texto) div 2),lin); textcolor(color); write(texto) End;

PROCEDURE Inicio;
Begin
 Valores_Iniciales(accion,contador,base,altura,minas,libres,b_d_x,b_d_y,comienzo);
 Inicializo_Matriz(campo,base,altura);
 Minar_Campo(campo,base,altura,minas);
 Construye_Campo(campo,base,altura,b_d_x,b_d_y);
 Reescribe(nivel_anterior,0,principiante,intermedio,experto);
 nivel_anterior:=b_d_x;
 Reescribe(b_d_x,1,principiante,intermedio,experto);
 textcolor(red+8);
 gotoxy(5,9); write(minas:2); gotoxy(75,9); write(contador:4);
 fila:=altura div 2; columna:=base div 2;
 gotoxy(X(columna,b_d_x),Y(fila,b_d_y));
End;

PROCEDURE Textos_Fijos;
Begin
 Texto_Centrado('B U S C A M I N A S ',1,15);
 Reescribe(23,0,0,intermedio,0);
 Reescribe(9,0,0,0,experto);
 textcolor(15); gotoxy(4,22); write('J U G A R');
 textcolor(7);
 gotoxy(29,22); write('| [M] Marcar/Desmarcar');
 gotoxy(29,23); write('|  |->(x1) =   : Mina encontrada');
 gotoxy(29,24); write('|  |->(x2) =   : Posible mina');
 gotoxy(29,25); write('|  |->(x3) =   : Forma original');
 gotoxy(68,22); write('[ENTER]');
 gotoxy(65,23); write('Ver contenido');
 gotoxy(66,25); write('[Esc] Salir');
 gotoxy(41,25); write('[]');
 textcolor(red+8);
 gotoxy(3,7); write('MINAS');
 gotoxy(74,7); write('TIEMPO');
 gotoxy(41,23); write('[]');
 gotoxy(20,22); write('RECORDS');
 textcolor(yellow);
 gotoxy(41,24); write('??');
End;

PROCEDURE Marco_Desmarco;
Begin
 If campo[fila,columna].estado <> 0 then
 Case campo[fila,columna].estado of
  1:If minas > 0 then
     begin
      dec(minas); campo[fila,columna].estado:=2;
      Caracter(fila,columna,red);
      gotoxy(5,9); textcolor(red+8); write(minas:2)
     end;
  2:begin
     inc(minas); campo[fila,columna].estado:=3;
     Caracter(fila,columna,yellow);
     gotoxy(5,9); textcolor(red+8); write(minas:2)
    end;
  3:begin campo[fila,columna].estado:=1; Caracter(fila,columna,7); end
 end
End;

PROCEDURE Marco_Minas;{cuando solo quedan celdas con minas}
Var fil,col:byte;
Begin
 For fil:=1 to altura do
  For col:=1 to base do
   If (campo[fil,col].contenido = 9)and(campo[fil,col].estado <> 2)then
    begin
     gotoxy(x(col,b_d_x),Y(fil,b_d_y));
     Caracter(fil,col,red)
    end;
 minas:=0; textcolor(red+8); gotoxy(5,9); write(minas:2)
End;

PROCEDURE Perdi(fil,col:byte);
Var f_aux,c_aux:byte;
Begin
 f_aux:=fil; c_aux:=col; textcolor(15);
 For fil:=1 to altura do
  For col:=1 to base do
   If (campo[fil,col].contenido=9)and( (fil<>f_aux) or (col<>c_aux) ) then
    begin gotoxy(X(col,b_d_x),Y(fil,b_d_y)); write('<>') end
End;

PROCEDURE Enter;
Begin
 If not comienzo then begin comienzo:=true; gettime(h,m,seg,cs) end;
 If (campo[fila,columna].estado <> 2)and(campo[fila,columna].estado <> 0) then
 Case campo[fila,columna].contenido of
  0..8:begin
         If campo[fila,columna].contenido = 0
            then Libera(campo,fila,columna,base,altura,libres)
            else begin
                      dec(libres); campo[fila,columna].estado:=0;
                      Numero(campo[fila,columna].contenido)
                 end;
         If libres = 0 then
            begin
             Marco_Minas;
             New_Record(b_d_x,contador,principiante,intermedio,experto);
             repeat
              accion:=readkey
             until (accion='1')or(accion='2')or(accion='3')or(accion=esc);
             If accion <> esc then
                begin window(10,3,71,20); clrscr; window(1,1,screenwidth,25); Inicio end
            end
       end;
     9: begin
         textcolor(red+8); write('<>'); Perdi(fila,columna);
         repeat
                accion:=readkey
         until (accion='1')or(accion='2')or(accion='3')or(accion=esc);
         If accion <> esc then
            begin window(10,3,71,20); clrscr; window(1,1,screenwidth,25); Inicio end
        end
 end
End;

PROCEDURE hago;
Begin
 Case accion of
  '1'..'3': begin window(10,3,71,20); clrscr; window(1,1,screenwidth,25); inicio end;
       izq: Izquierda(campo,fila,columna,base);
       der: Derecha(campo,fila,columna,base);
       arr: Arriba(campo,fila,columna,altura);
       aba: Abajo(campo,fila,columna,altura);
       'm': Marco_Desmarco;
       ent: Enter;
 end
End;

PROCEDURE final;
Begin
 clrscr;
 texto_centrado('Realizado por:',3,15);
 texto_centrado('Agustin Dario Medina',7,15);
 texto_centrado('Terminado el 25/11/2012',12,15);
 texto_centrado('Ultima modificacion: 29/11/2015',13,15);
 texto_centrado('Agradecimientos',18,15);
 texto_centrado('A mi primo "Gabi" por prestarme su notebook',20,15);
 texto_centrado(' Presionar cualquier tecla para salir',25,7);
 repeat until keypressed; clrscr
End;

BEGIN
 clrscr;
 Randomize;
 accion:='1';
 principiante:=65535; intermedio:=65535; experto:=65535; nivel_anterior:=30;
 Textos_Fijos; Inicio;
 Repeat
  If comienzo and (s <> seg) then
   begin
        inc(contador); textcolor(red+8);
        gotoxy(75,9); write(contador:4); seg:=s
   end;
  If keypressed then begin accion:= readkey; hago end;
  Gettime(h,m,s,cs);
  gotoxy(X(columna,b_d_x),Y(fila,b_d_y));
 Until accion = esc;
 final
END.
