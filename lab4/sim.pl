#!/usr/bin/perl

# SIM, wersja 16.1.2008

# program wczytywany przez stdin, chyba ze podana nazwa pliku jako parametr
# w przypadku wczytywania przez stdin, od razu wykonuje i wychodzi (na stdout listing i tabelka stanu po wykonaniu)
# w przypadku wczytywania z pliku, dziala w trybie komend
# gdy bledy, to ich tresc na stderr

# $a,$b-rejestry @p-tresc programu, %e-etykiety, %v-zmienne, @s-stos, $c=zliczone cykle
# $sp-wskaznik stosu (wskazuje nastepne wolne miejsce na stosie)
# $bp-dodatkowy rejestr wskaznikowy
# $pc-licznik programu, $zf-flaga zera (0 lub 1), $cf-flaga przeniesienia (0 lub 1)
# $bpc-poprzednia wartosc licznika programu
# linie numerowane sa od 0. dla celow prezentacji numerowane od 1
# @sl-zawiera numery linii pod ktorymi sa kolejne instrukcje
# @ss-zawiera "a" tam gdzie element stosu jest adresem z instrukcji call i "?" w przeciwnym wypadku
use integer

$a=$b=0; $sp=$bp=0; @p=(); %e=(); %v=(); @s=(); @ss=(); $c=0; $bpc=-1; $pc=0; $zf=$cf=0; @sl=(); 


# naglowek 
print "======== SIM ========\n"; 

# czytanie programu
if(!($fin=pop)) { 
    print "* reading program from stdin..."; 
    @p=<>;
} else { 
    print "* reading from file $fin...";
    open PROG,"<$fin" or die "failed (file not found).\n";
    @p=<PROG>; close PROG
}
print "OK\n";

# wylistuj wszystko na poczatek
listuj();

# sprawdz, czy program poprawny syntaktycznie, 
# zbieranie etykiet, zmiennych i obcinanie enterow
# i wypelnianie @sl
przejrzyj();

# program w porzadku
print "======= start =======\n";

# jesli wczytano program ze stdin, to od razu wykonaj i wypisz wynik koncowy
if(!$fin) {
    while(exists $sl[$pc]) { last unless rozkaz($p[$sl[$pc]]) }
    print "======== stop =======\n* program ended at line ",$sl[$pc],"\n";
    stan();
    stanzmiennych();
    exit;
}

# jesli wczytano program z pliku, to dzialaj w trybie konsoli
pomoc(); 
$li=""; # to co wpisal uzytkownik ostatnim razem
for(;;) {
    print "sim>"; chomp($_=lc <>); s/\s//g; last if /^q/;
    $_=$li if /^$/; 
    $li=$_;
    if(/^\?$/) {
        pomoc()
    }elsif(/^r$/){
        if(exists $sl[$pc]) {
            print "* running...\n";
            while(exists $sl[$pc]) { last unless rozkaz($p[$sl[$pc]]) }
            print "* program ended at line ",$sl[$bpc]+1,"\n";
            stan()
        } else { 
            print "* program stopped. use x to reset.\n" 
        }
    }elsif(/^t$/){
        if(exists $sl[$pc]) {
            print "* running to nearest BRK...\n";
            while(exists $sl[$pc]) { last if rozkaz($p[$sl[$pc]])==3 }
            stan() 
        } else { 
            print "* program stopped. use x to reset.\n" 
        }
    }elsif(/^s$/){
        if(exists $sl[$pc]) {
            print "* executing: ",$p[$sl[$pc]],"\n"; 
            rozkaz($p[$sl[$pc]]);
            stan() 
        } else { 
            print "* program stopped. use x to reset.\n" 
        }
    }elsif(/^t(\d+)$/){
        $i=$1;
        if(exists $sl[$pc]) {
            print "* tracing $i steps...\n";
            while($i--&&exists $sl[$pc]) {
                while(exists $sl[$pc]) { last if rozkaz($p[$sl[$pc]])==3 }
            }
            stan() 
        } else { 
            print "* program stopped. use x to reset.\n" 
        }
    }elsif(/^s(\d+)$/){
        $i=$1;
        if(exists $sl[$pc]) {
            print "* running $i steps...\n";
            rozkaz($p[$sl[$pc]]) while $i--&&exists $sl[$pc];
            stan() 
        } else { 
            print "* program stopped. use x to reset.\n" 
        }
    }elsif(/^l$/){
        listuj()
    }elsif(/^k$/){
        stakstan()
    }elsif(/^l(\d+)$/){
        listuj($1)
    }elsif(/^l(\d*):(\S+)$/){
        if($1) { listuj($1,$2) } else { listuj(10,$2) }
    }elsif(/^v$/){
        stanzmiennych()	
    }elsif(/^x$/){
        print "* clearing stack\n"; @s=(); @ss=();
        print "* clearing cycle count\n"; $c=0;
        print "* clearing registers\n"; $a=$b=$bp=$sp=0;
	print "* clearing flags\n"; $cf=$zf=0;	
        print "* clearing program counter\n"; $pc=0; $bpc=-1;
        print "* reloading program from file $fin...";
        open PROG,"<$fin" or die "failed (file not found).\n";
        @p=<PROG>; close PROG;
        print "OK\n";
        przejrzyj();
    }elsif(/^p$/){
        stan()
    }else{
        print "unknown command\n"
    }
}
print "Bye\n";

# jesli rozkaz($tresc), to wykonanie
# jesli rozkaz($tresc,"v"), to tylko weryfikacja, bez poprawnosci etykiet i zmiennych
# jesli rozkaz($tresc,"vv"), to weryfikacja, lacznie z poprawnoscia etykiet i zmiennych
# zwraca niezero, jesli dobra instrukcja (w tym 1 jesli cos tam bylo lub 2 jesli pusta)
sub rozkaz {
    $_=lc shift; s/\s//g; s/^[^:]*://; s/;.*$//; # wycinanie etykiety, spacji i komentarza
    my $mode=shift;
    $bpc=$pc unless $mode=~/v/; 
    if(/^$/||/^dd/) { # linia pusta lub deklaracja zmiennej
        return 2;
    }elsif(/^brk$/) {
        $pc++ unless $mode=~/v/;
        return 3;    
    }elsif(/^mova,#(\-?\d+)$/) {
        unless($mode=~/v/) { 
            $a=$1; $c+=2; $pc++; 
            $zf=$a?0:1;
        }
        return 1;
    }elsif(/^mova,\[bp\]$/) {
        unless($mode=~/v/) {
            if($bp<0||$bp>$#s) {
                print "* error: illegal address\n";
                return $a=0;
            }
            $a=$s[$bp]; $c+=3; $pc++;
            $zf=$a?0:1;
        }
        return 1; 
    }elsif(/^mov\[bp\],a$/) {
        unless($mode=~/v/) {
            if($bp<0) {
                print "* error: illegal address\n";
                return 0;
            }
            $s[$bp]=$a; $ss[$bp]="?"; $c+=3; $pc++;
            $zf=$a?0:1;
        }
        return 1;  
    }elsif(/^mova,\[sp\]$/) {
        unless($mode=~/v/) {
            if($sp<0||$sp>$#s) {
                print "* error: illegal address\n";
                return $a=0;
            }
            $a=$s[$sp]; $c+=3; $pc++;
            $zf=$a?0:1;
        }
        return 1;
    }elsif(/^mov\[sp\],a$/) {
        unless($mode=~/v/) {
            if($sp<0) {
                print "* error: illegal address\n";
                return 0;
            }
            $s[$sp]=$a; $ss[$sp]="?"; $c+=3; $pc++;
            $zf=$a?0:1;
        }
        return 1;
    }elsif(/^mova,\[bp([\+\-])(\d+)\]$/) {
        unless($mode=~/v/) { 
            if($1 eq "-"&&($bp-$2<0||$bp-$2>$#s)||$1 eq "+"&&($bp+$2>$#s)) {
                print "* error: illegal address\n";
                return $a=0;
            }
            $a=$1 eq "-"?$s[$bp-$2]:$s[$bp+$2]; $c+=4; $pc++;
            $zf=$a?0:1;
        }
        return 1;
    }elsif(/^mov\[bp([\+\-])(\d+)\],a$/) {
        unless($mode=~/v/) { 
            if($1 eq "-"&&$bp-$2<0) {
                print "* error: illegal address\n";
                return 0;
            }
            if($1 eq "-") { $s[$bp-$2]=$a; $ss[$bp-$2]="?" } else { $s[$bp+$2]=$a; $ss[$bp+$2]="?" } $c+=4; $pc++;
            $zf=$a?0:1;
        }
        return 1;
    }elsif(/^mova,\[sp([\+\-])(\d+)\]$/) {
        unless($mode=~/v/) { 
            if($1 eq "-"&&($sp-$2<0||$sp-$2>$#s)||$1 eq "+"&&($sp+$2>$#s)) {
                print "* error: illegal address\n";
                return $a=0;
            }
            $a=$1 eq "-"?$s[$sp-$2]:$s[$sp+$2]; $c+=4; $pc++;
            $zf=$a?0:1;
        }
        return 1;
    }elsif(/^mov\[sp([\+\-])(\d+)\],a$/) {
        unless($mode=~/v/) { 
            if($1 eq "-"&&$sp-$2<0) {
                print "* error: illegal address\n";
                return 0;
            }
            if($1 eq "-") { $s[$sp-$2]=$a; $ss[$sp-$2]="?" } else { $s[$sp+$2]=$a; $ss[$sp+$2]="?" } $c+=4; $pc++;
            $zf=$a?0:1;
        }
        return 1;
    }elsif(/^mova,\[([^\]]+)\]$/) {
        if($mode ne "v") { return 0 unless exists $v{$1} } # niepoprawny adres
        unless($mode=~/v/) { 
            $a=$v{$1}; $c+=3; $pc++;
            $zf=$a?0:1;
        }
        return 1;
    }elsif(/^mov\[([^\]]+)\],a$/) {
        if($mode ne "v") { return 0 unless exists $v{$1} } # niepoprawny adres
        unless($mode=~/v/) { 
            $v{$1}=$a; $c+=3; $pc++; 
            $zf=$a?0:1;
        }
        return 1;
    }elsif(/^mov([a-z]+),([a-z]+)$/) {
        return 0 if($1 ne "a"&&$1 ne "b"&&$1 ne "sp"&&$1 ne "bp");
        return 0 if($2 ne "a"&&$2 ne "b"&&$2 ne "sp"&&$2 ne "bp");
        unless($mode=~/v/) { 
            eval '$_=$'.$1.'=$'.$2; 
            $c++; $pc++; 
            $zf=$_?0:1;
        }
        return 1;
    }elsif(/^pusha$/) {
        unless($mode=~/v/) { 
            $ss[$sp]="?"; $s[$sp++]=$a; $c+=2; $pc++; 
            $zf=$a?0:1;
        }
        return 1;
    }elsif(/^pushb$/) {
        unless($mode=~/v/) { 
            $ss[$sp]="?"; $s[$sp++]=$b; $c+=2; $pc++; 
            $zf=$b?0:1;
        }
        return 1; 
    }elsif(/^pushbp$/) {
        unless($mode=~/v/) { 
            $ss[$sp]="?"; $s[$sp++]=$bp; $c+=2; $pc++; 
            $zf=$bp?0:1;
        }
        return 1; 
    }elsif(/^popa$/) {
        unless($mode=~/v/) { 
            if($sp<=0||$sp-1>$#s) {
                print "* error: pop address out of range\n";
                return $a=0;
            }
            $sp--; $a=$s[$sp]; if($sp==$#s) { pop @s; pop @ss } 
            $c+=2; $pc++; 
            $zf=$a?0:1;
        }
        return 1;
    }elsif(/^popb$/) {
        unless($mode=~/v/) { 
            if($sp<=0||$sp-1>$#s) {
                print "* error: pop address out of range\n";
                return $b=0;
            }
            $sp--; $b=$s[$sp]; if($sp==$#s) { pop @s; pop @ss } 
            $c+=2; $pc++; 
            $zf=$b?0:1;
        }
        return 1;
    }elsif(/^popbp$/) {
        unless($mode=~/v/) { 
            if($sp<=0||$sp-1>$#s) {
                print "* error: pop address out of range\n";
                return $b=0;
            }
            $sp--; $bp=$s[$sp]; if($sp==$#s) { pop @s; pop @ss } 
            $c+=2; $pc++; 
            $zf=$bp?0:1;
        }
        return 1;
    }elsif(/^adda,b$/) {
        unless($mode=~/v/) { 
            $a+=$b; $c++; $pc++; 
            $zf=$a?0:1;
        }
        return 1;
    }elsif(/^suba,b$/) {
        unless($mode=~/v/) { 
            $a-=$b; $c++; $pc++; 
            $zf=$a?0:1;
            $cf=$a<0?1:0;
        }
        return 1;
    }elsif(/^mula,b$/) {
        unless($mode=~/v/) { 
            $a*=$b; $c+=2; $pc++;
            $zf=$a?0:1; 
        }
        return 1;
    }elsif(/^diva,b$/) {
        unless($mode=~/v/) { 
            unless($b) { 
                print "* error: division by zero\n";
                return $a=0;
            }
            $a=int($a/$b); 
            $c+=3; $pc++; 
            $zf=$a?0:1;
        }
        return 1;
    }elsif(/^nega$/) {
        unless($mode=~/v/) { 
            $a=-$a; $c++; $pc++; 
            $zf=$a?0:1;
        }
        return 1;
    }elsif(/^xora,b$/) {
        unless($mode=~/v/) { 
            $a ^= $b; $c++; $pc++;
            $zf=$a?0:1; 
        }
        return 1;
    }elsif(/^ora,b$/) {
        unless($mode=~/v/) { 
            $a |= $b; $c++; $pc++;
            $zf=$a?0:1; 
        }
        return 1;
    }elsif(/^anda,b$/) {
        unless($mode=~/v/) { 
            $a &= $b; $c++; $pc++;
            $zf=$a?0:1; 
        }
        return 1;
    }elsif(/^nota$/) {
        unless($mode=~/v/) { 
						$a += 0; #nie wiem dlaczego ale bez tego nie dzia³a
            $a = ~$a; $c++; $pc++; 
            $zf=$a?0:1;
        }
        return 1;
    }elsif(/^cmpa,b$/) {
        unless($mode=~/v/) { 
            $c++; $pc++; 
            $zf=$a==$b?1:0;
            $cf=$a<$b?1:0;
        }
        return 1;
    }elsif(/^call(.+)$/) {
        if($mode ne "v") { return 0 unless exists $e{$1} } # niepoprawny adres wywolania
        unless($mode=~/v/) { 
            $ss[$sp]="a"; $s[$sp++]=$pc+1;
            $pc=$e{$1}; $c+=4; 
        }        
        return 1;   
    }elsif(/^ret$/) {
        unless($mode=~/v/) { 
            if($sp<=0||$sp-1>$#s) {
                print "* error: cannot pop address\n";
                return 0;
            }
            $sp--; $pc=$s[$sp]; if($sp==$#s) { pop @s; pop @ss } 
            $c+=4; 
        }
        return 1;        
    }elsif(/^jmp(.+)$/) {
        if($mode ne "v") { return 0 unless exists $e{$1} } # niepoprawny adres skoku
        unless($mode=~/v/) { $pc=$e{$1}; $c+=2; }
        return 1;
    }elsif(/^je(.+)$/) {
        if($mode ne "v") { return 0 unless exists $e{$1} } # niepoprawny adres skoku
        unless($mode=~/v/) { $pc=$zf?$e{$1}:$pc+1; $c=$zf?$c+2:$c+1; }
        return 1;
    }elsif(/^jne(.+)$/) {
        if($mode ne "v") { return 0 unless exists $e{$1} } # niepoprawny adres skoku
        unless($mode=~/v/) { $pc=$zf?$pc+1:$e{$1}; $c=$zf?$c+1:$c+2; }
        return 1;
    }elsif(/^jge(.+)$/) {
        if($mode ne "v") { return 0 unless exists $e{$1} } # niepoprawny adres skoku
        unless($mode=~/v/) { $pc=$cf?$pc+1:$e{$1}; $c=$cf?$c+1:$c+2; }
        return 1;
    }elsif(/^jle(.+)$/) {
        if($mode ne "v") { return 0 unless exists $e{$1} } # niepoprawny adres skoku
        unless($mode=~/v/) { $pc=$cf||$zf?$e{$1}:$pc+1; $c=$cf||$zf?$c+2:$c+1; }
        return 1;
    }elsif(/^jl(.+)$/) {
        if($mode ne "v") { return 0 unless exists $e{$1} } # niepoprawny adres skoku
        unless($mode=~/v/) { $pc=$cf?$e{$1}:$pc+1; $c=$cf?$c+2:$c+1; }
        return 1;
    }elsif(/^jg(.+)$/) {
        if($mode ne "v") { return 0 unless exists $e{$1} } # niepoprawny adres skoku
        unless($mode=~/v/) { $pc=$cf||$zf?$pc+1:$e{$1}; $c=$cf||$zf?$c+1:$c+2; }
        return 1;
    }else{
        return 0
    }
}

# wyswietla zawartosc zmiennych
sub stanzmiennych {
    print "====== variable list ======\n";
    print "  (no variables)\n" unless keys %v;
    for(keys %v) { print "$_ = ",$v{$_},"\n" }
    print "=== end of variable list ==\n";
}

# wyswietla stan procesora (i stos tez)
sub stan {
    print  "+-----------+--------------+--------------+\n";
    printf "| registers | A: %9d | B: %9d |\n",$a,$b;
    printf "|   HEX     |    %09x |    %09x |\n",$a,$b;
    print  "+-----------+--------------+--------------+\n";
    printf "            | SP: %8d | BP: %8d |\n",$sp,$bp;
    print  "+-------+---+--+------+----+--------------+\n";
    print  "| flags | Z: $zf | C: $cf |\n";
    print  "+-------+------+------+--+\n";
    printf "|  current pc: %9d |     next line : %s\n",$pc,exists $sl[$pc]?$p[$sl[$pc]]:"<program ended>";
    print  "+------------------------+\n";
    printf "| previous pc: %9d | previous line : %s\n",$bpc,$bpc>=0?$p[$sl[$bpc]]:"<nothing>";
    print  "+------------------------+\n";
    printf "| cycle count: %9d |\n",$c;
    print  "+------------------------+-----------+\n";
    stakstan()
}

sub stakstan {
    my $nstk=0; # numer elementu na stosie

    print  "+------------------------------------+\n";
    print  "| =========== stack bottom ========= |\n";
    
    for(@s) { 
        if($ss[$nstk] ne "a") { printf "| %s %s %20d     |\n",$nstk==$sp?"sp->":"    ",$nstk==$bp?"bp->":"    ",$_; }
        else { printf "| %s %s %20s     |\n",$nstk==$sp?"sp->":"    ",$nstk==$bp?"bp->":"    ","adr:$_ (line:".($_<=$#sl?$sl[$_]+1:$#p+2).")" }
        $nstk++;
    }
    while($nstk<=$sp||$nstk<=$bp) {
        printf "| %s %s %20s     |\n",$nstk==$sp?"sp->":"    ",$nstk==$bp?"bp->":"    ","?";
        $nstk++;
    }

    print  "| =========== top of stack ========= |\n";
    print  "+------------------------------------+\n";
}

# sprawdz, czy program poprawny syntaktycznie, zbieranie etykiet i zmiennych i obcinanie enterow
sub przejrzyj {
    %e=(); %v=(); @sl=();
    print "* checking program text...";
    my $n=0; # numer linii
    my $in=0; # numer instrukcji
    my $rcode; # kod zwrocony przez rozkaz()
    my $l; # przegladana linia
    for $l(@p) {
        chomp($l);
        if($l=~m/^\s*(\S+)\s*:/) { # etykieta?
            exists $e{lc $1} and die "failed at line ",$n+1,": \"$l\" (label name must be unique)";
            $e{lc $1}=$in
        }
        if($l=~m/^\s*dd\s*(\S+)\s*$/i) { # zmienna?
            exists $v{lc $1} and die "failed at line ",$n+1,": \"$l\" (variable already exists)";
            $v{lc $1}=0
        }
        $rcode=rozkaz($l,"v") or die "failed at line ",$n+1,": \"$l\" (syntax error)";
        if($rcode==1||$rcode==3) {
            push @sl,$n;
            $in++;
        }
        $n++;
    }
                 
    # sprawdz, czy nie ma odwolan do nieistniejacych zmiennych i etykiet
    $n=0; # numer linii
    for $l(@p) {
        rozkaz($l,"vv") or die "failed at line ",$n+1,": \"$l\" (reference to undefined label or variable)";
        $n++;
    }
    print "OK\n";

    # punkt wejscia
    if(exists $e{"start"}) {
        print "* setting pc to ",($pc=$e{"start"}),"\n"
    } else {
        print "* \"start\" label not found. assuming entry point at instruction 0\n"
    }
}

# help n/t komend
sub pomoc { 
    print "=== commands:\n=== ? - display command list\n+++\n=== r - run until end\n=== s - one step forward\n".
      "=== sN - N steps forward\n".
      "=== t - run to nearest BRK\n=== tN - run to nearest N-th BRK\n+++\n".
      "=== p - processor state\n=== v - variable state\n=== k - stack state\n+++\n".
      "=== l - list all\n=== lN - list around pc (2 backwd, N fwd)\n".
      "=== lN:M - list around line M (2 backwd, N fwd. N is optional - default N=10)\n".
      "=== lN:label - list arnd label (2 backwd, N fwd. N is optional - default N=10)\n+++\n".
      "=== x - program reset\n=== q - quit\n".
      "=== (enter empty line to repeat last command)\n"
}

# listowanie programu
# jesli bez parametru - caly
# jesli z parametrem - od linii $pc-2 wlacznie do $pc+parametr wlacznie
# jesli z dwoma parametrami - od linii (drugi param, moze byc etykieta, a jesli linia
# to numerowana od 1) do (drugim param)+(pierwszy param) wlacznie
sub listuj {
    my $n=0; my $rel,$around,$lstart,$lend;  

    # wycinanie pustych linii z konca
    while(@p>0) {
        if($p[$#p]=~/^\s*$/) { pop @p } else { last }
    }

    # listing itself
    print "=== listing starts ===\n";
    if(@_>0) { # tylko dane linie
        $around=shift;
        if(@_>0) { # od wskazanej linii/etykiety
            $rel=shift;
            if($rel=~/\d+/) { $rel--; $lstart=$rel-2; $lend=$rel+$around }
            else {
                unless(exists $e{$rel}) {
                    print "* error: label \"$rel\" not found.\n";
                    return;
                }
                $lstart=$sl[$e{$rel}]-2;
                $lend=$sl[$e{$rel}]+$around
            }
        } else { # od pece
            if($pc<=$#sl) { $lstart=$sl[$pc]-2; $lend=$sl[$pc]+$around }
            else { $lstart=$#p-1; $lend=$#p }
        }
        $lstart=$#p if $lstart>$#p;
        $lstart=0 if $lstart<0;
        $lend=$#p if $lend>$#p;       
        $n=$lstart;
        print "     (...)\n" if $lstart>0;
        while($n<=$lend) { # tylko wybrane linie
            if($pc&&exists $sl[$pc] and $n==$sl[$pc]) { print "---> " } else { print "     " }
            printf "%4d %s\n",$n+1,$p[$n],"\n";
            $n++;
        }
        print "     (...)\n" if $lend<$#p
    } else { # wszystko
        for $l(@p) { 
            chomp($l);
            if($pc&&exists $sl[$pc] and $n==$sl[$pc]) { print "---> " } else { print "     " }
            printf "%4d %s\n",$n+1,$p[$n],"\n";
            $n++;
        }
    }
    print "==== listing ends ====\n";
}





