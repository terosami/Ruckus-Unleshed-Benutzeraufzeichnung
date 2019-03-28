#/bin/bash

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    Dieses Programm ist Freie Software: Sie können es unter den Bedingungen
#    der GNU General Public License, wie von der Free Software Foundation,
#    Version 3 der Lizenz oder (nach Ihrer Wahl) jeder neueren
#    veröffentlichten Version, weiter verteilen und/oder modifizieren.
#
#    Dieses Programm wird in der Hoffnung bereitgestellt, dass es nützlich sein wird, jedoch
#    OHNE JEDE GEWÄHR,; sogar ohne die implizite
#    Gewähr der MARKTFÄHIGKEIT oder EIGNUNG FÜR EINEN BESTIMMTEN ZWECK.
#    Siehe die GNU General Public License für weitere Einzelheiten.
#
#    Sie sollten eine Kopie der GNU General Public License zusammen mit diesem
#    Programm erhalten haben. Wenn nicht, siehe <https://www.gnu.org/licenses/>.

#    Author: Gregor Holzfeind
#    Datum:
#    Version: 0.2

##########################
#  Anpassbare Variablen  #
##########################

log_location="/var/log/192.168.0.8/syslog.log"    # Speicherpfad der Syslogdatei
ssid="Test_Gast"    # zu Anlalysierende SSID
database="csv"    # Speichervariante der Enddaten. Mögliche Werte: csv, sql
mac_only="false"    # Nur MAC-Adressen speichern = true. MAC-Adresse und Benutzername speichern = false.

#####################
#  Leere Variablen  #
#####################

mac_error=""

#####################
#  Hauptfunktionen  #
#####################

function func_check(){
        if [ "$mac_only" != "true" -o "$mac_only" != "false" ]
        then
                mac_error="true"
        fi
}

function func_analyse(){
        cat $log_location | grep "$ssid" | grep "User" > log_redu.tmp.$$    # Log auf die wichtigen Informationen reduzieren.
        while read input
        do
                # Type des Log-Eintrag ermitteln
                func_log_typ
                if [ "$connection" = ""  ] # Auf Roaming und sontige Einträge reagieren.
                then
                        continue
                fi
                # MAC-Adresse und Benutzername ermitteln
                func_mac_user
                # Uhrzeit der Aktivität ermitteln
                func_time
                # Eintrag vorbereiten
                func_pre_entry
        done < log_redu.tmp.$$
}

function func_preparation(){
        cat pre_entry_join.tmp | cut -d";" -f3 | uniq | sort > uniq_mac.tmp.$$
        func_join_final
}

function func_data_csv() {
        echo "csv"
}

function func_data_sql(){
        echo "sql"
}

function func_end(){
        rm *.$$
        exit
}
######################
#   Nebenfunktionen  #
######################

function func_mac_user(){
        if [ "$mac_only" = "true" ]
        then
                mac=$(echo $input | cut -d"[" -f2 | cut -d"]" -f1)
        elif [ "$mac_only" = "false" ]
        then
                mac=$(echo $input | cut -d"[" -f2 | cut -d"]" -f1 | cut -d"@" -f2)
                username=$(echo $input | cut -d"[" -f2 | cut -d"]" -f1 | cut -d"@" -f1)
        else
                echo "Falscher Wert bei der Variabel " '"$mac_only".'
                echo "Der Aktuelle Wert ist: " $mac_only
                echo -e "\nDie einzig zugelassen Werte sind: true oder false"
                echo -e "\nDen Wert im Script anpassen und erneut durchführen"
                echo -e "\n\nDas Script wird nun beendet und ein entsprechender Log-Eintrag wird angelegt"
                logger guest_user.sh: error mac_only wronge value. ssid: $ssid, mac_only: $mac_only
                exit
        fi
}

function func_log_typ(){
        joins_e=$(echo $input | grep "joins" | cut -d" " -f1)
        joins_d=$(echo $input | grep "tritt" | cut -d" " -f1)
        leave_e=$(echo $input | grep "leave" | cut -d" " -f1)
        leave_d=$(echo $input | grep "verlässt" | cut -d" " -f1)
        if [ "$joins_e" != "" -o "$joins_d" != "" ]
        then
                connection="join"
        elif [ "$leave_e" != "" -o  "$leave_d" != "" ]
        then
                connection="leave"
                session_time=$(echo $input | cut -d"[" -f5 | cut -d" " -f1)
                rx=$(echo $input | cut -d"[" -f6 | cut -d"]" -f1)
                tx=$(echo $input | cut -d"[" -f7 | cut -d"]" -f1)
        fi
}

function func_pre_entry(){
        if [ "$mac_only" = "true" ]
        then
                if [ "$connection" = "join" ]
                then
                        echo "$year.$month.$day;$clock;$mac" >> pre_entry_join.tmp
                elif [ "$connection" = "leave" ]
                then
                        echo "$year.$month.$day;$clock;$mac;$session_time;$rx;$tx" >> pre_entry_leave.tmp
                fi
        elif [ "$mac_only" = "false" ]
        then
                if [ "$connection" = "join" ]
                then
                        echo "$year.$month.$day;$clock;$mac;$username" >> pre_entry_join.tmp
                elif [ "$connection" = "leave" ]
                then
                        echo "$year.$month.$day;$clock;$mac;$username;$session_time;$rx;$tx" >> pre_entry_leve.tmp
                fi

        fi
}
function func_time(){
        month_pre=$(echo $input | cut -d" " -f1)
        day=$(echo $input | cut -d" " -f2)
        clock=$(echo $input | cut -d" " -f3)
        case "$month_pre" in
                Jan) month="01" ;;
                Feb) month="02" ;;
                Mar) month="03" ;;
                Apr) month="04" ;;
                May) month="05" ;;
                June) month="06" ;;
                July) month="07" ;;
                Aug) month="08" ;;
                Sept) month="09" ;;
                Oct) month="10" ;;
                Nov) month="11" ;;
                Dec) month="12" ;;
                *) month="$month_pre" ;;
        esac
        year=$(date +%y)
}

function func_header_csv(){
        echo "Username;MAC-Adresse;Anzahl Sessionen;Start Session;Ende Session;Total RX;Total TX" > log_$ssid.csv
}

function func_join_final(){
        while read input
        do
                cat pre_entry_join.tmp | grep "$input" | cut -d";" -f4| uniq > username.tmp.$$
                while read input2
                do
                        number_session=$(cat pre_entry_join.tmp | grep "$input2" | wc -l)
                        first_session=$(cat pre_entry_join.tmp | grep "$input2" | head -n1| cut -d";" -f1-2)
                        echo "$input2;$input;$number_session;$first_session" >> entry_join.tmp
                done < username.tmp.$$
        done < uniq_mac.tmp.$$
}

##############
#  Programm  #
##############

#func_check
func_analyse
func_preparation
if [ "$database" = "csv" ]
then
        func_data_csv
elif [ "$database" = "mysql" ]
then
        func_data_sql
fi
func_end
