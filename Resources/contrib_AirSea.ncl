;============= plotting shortcuts ==================================
undef("trimPNG")
procedure trimPNG(fig_file)
local res,cmd
; this code was written by Walter Hannah (hannahlab.org)
begin
   strver = systemfunc("ncl -V") 
   ver = tofloat(strver)
   sub = str_sub_str(strver,ver+".","")
   if .not.isStrSubset(fig_file,".png") then 
       fig_file = fig_file + ".png" 
   end if
   ;print("fig file = " + fig_file)
   cmd = "convert -trim "+fig_file+" "+fig_file
   ;print("cmd = " + cmd)
   if (ver.ge.6.2) .or. ((ver.eq.6.2).and.(sub.ge.1)) then
       if fileexists(fig_file) then system(cmd) end if
   else
       if isfilepresent(fig_file) then system(cmd) end if
   end if
   ;print("    "+fig_file)
end

;============= substring ==================================
undef("substring")
function substring (instr[1]:string, first[1]:numeric, last[1]:numeric)

local instr, first, last, main, p2

begin
   main = stringtochar (instr)		; convert input string to char array
									; terminal null character is included   
   
   if (last .ge. first) then		; check requested end position
      p2 = last						; go to last position specified
   else								; but if less than first:
      p2 = dimsizes (main) - 2		; go to last avail char in main string
   end if
   
   return (chartostring (main(first:p2)))	; extract substring
end


