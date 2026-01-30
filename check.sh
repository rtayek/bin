for file in frog .profile .bash_history .bash_aliases .bash_profile  .bashrc
    do
    echo $file
    if  grep -qU $'\015' $file
        then
        echo yes
        dos2unix $file
        else echo no
    fi
    done
    
