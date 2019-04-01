#!/bin/bash

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
#    Datum: 28.03.2019
#    Version: 0.5

##########################
#  Anpassbare Variablen  #
##########################

log_location="/var/log/192.168.0.8/syslog.log"    # Speicherpfad der Syslogdatei
ssid="Test_Gast"    # zu Anlalysierende SSID
database="csv"    # Speichervariante der Enddaten. Mögliche Werte: csv, sql
mac_only="false"    # Nur MAC-Adressen speichern = true. MAC-Adresse und Benutzername speichern = false.
csv_path="$HOME"    # Speicherplatz der CSV-Datei

#####################
#  Leere Variablen  #
#####################

mac_error=""

####################
#  Fixe Variablen  #
####################

csv_full_path="$csv_path/LOG_$ssid.csv"


#####################
#  Hauptfunktionen  #
#####################

function func_check(){
        if [ "$mac_only" != "true" -o "$mac_only" != "false" ]
        then
                mac_error="true"
        fi
		
		if [ $mac_error = "true" ]
		then
			echo "Falscher Wert bei der Variabel " '"$mac_only".'
            echo "Der Aktuelle Wert ist: " $mac_only
            # echo -e "\nDie einzig zugelassen Werte sind: true oder false"
            echo -e "\nDen Wert im Script anpassen und erneut durchführen"
            echo -e "\n\nDas Script wird nun beendet und ein entsprechender Log-Eintrag wird angelegt"
            logger guest_user.sh: error mac_only wronge value. ssid: $ssid, mac_only: $mac_only
            exit
		fi
}

function func_analyse(){
       grep "$ssid"  "$log_location"| grep "User" > log_redu.tmp.$$    # Log auf die wichtigen Informationen reduzieren.
        while read -r input_analyse
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
        cut -d";" -f3 pre_entry_join.tmp.$$ | uniq | sort > uniq_mac.tmp.$$
        func_join_final
        func_leave_final
		}

function func_data_csv(){
        func_header_csv
        func_replace_join_csv
        func_replace_leave_csv
        func_replace_csv
}

function func_data_sql(){
        echo "Wird einer späteren Version noch eingeführt"
}

function func_end(){
        rm ./*.$$
        exit
}
######################
#   Nebenfunktionen  #
######################

function func_mac_user(){
        if [ "$mac_only" = "true" ]
        then
                mac=$(echo "$input_analyse" | cut -d"[" -f2 | cut -d"]" -f1)
        elif [ "$mac_only" = "false" ]
        then
                mac=$(echo "$input_analyse" | cut -d"[" -f2 | cut -d"]" -f1 | cut -d"@" -f2)
                username=$(echo "$input_analyse" | cut -d"[" -f2 | cut -d"]" -f1 | cut -d"@" -f1)
        fi
}

function func_log_typ(){
        joins_e=$(echo "$input_analyse" | grep "joins" | cut -d" " -f1)
        joins_d=$(echo "$input_analyse" | grep "tritt" | cut -d" " -f1)
        leave_e=$(echo "$input_analyse" | grep "leave" | cut -d" " -f1)
        leave_d=$(echo "$input_analyse" | grep "verlässt" | cut -d" " -f1)
        if [ "$joins_e" != "" -o "$joins_d" != "" ]
        then
                connection="join"
        elif [ "$leave_e" != "" -o  "$leave_d" != "" ]
        then
                connection="leave"
                session_time=$(echo "$input_analyse" | cut -d"[" -f5 | cut -d" " -f1)
                rx=$(echo "$input_analyse" | cut -d"[" -f6 | cut -d"]" -f1)
                tx=$(echo "$input_analyse" | cut -d"[" -f7 | cut -d"]" -f1)
        fi
}

function func_pre_entry(){
        if [ "$mac_only" = "true" ]
        then
                if [ "$connection" = "join" ]
                then
                        echo "$year.$month.$day;$clock;$mac" >> pre_entry_join.tmp.$$
                elif [ "$connection" = "leave" ]
                then
                        echo "$year.$month.$day;$clock;$mac;$session_time;$rx;$tx" >> pre_entry_leave.tmp.$$
                fi
        elif [ "$mac_only" = "false" ]
        then
                if [ "$connection" = "join" ]
                then
                        echo "$year.$month.$day;$clock;$mac;$username" >> pre_entry_join.tmp.$$
                elif [ "$connection" = "leave" ]
                then
                        echo "$year.$month.$day;$clock;$mac;$username;$session_time;$rx;$tx" >> pre_entry_leave.tmp.$$
                fi
        fi
}
function func_time(){
        month_pre=$(echo "$input_analyse" | cut -d" " -f1)
        day=$(echo "$input_analyse" | cut -d" " -f2)
        clock=$(echo "$input_analyse" | cut -d" " -f3)
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

function func_join_final(){
        while read -r input_join_final
        do
                grep "$input_join_final" pre_entry_join.tmp.$$ | cut -d";" -f4| uniq > username.tmp.$$
                while read -r input_join_final_2
                do
                        number_session=$(grep -c "$input_join_final_2" pre_entry_join.tmp.$$)
                        first_session=$(grep "$input_join_final_2" pre_entry_join.tmp.$$ | head -n1| cut -d";" -f1-2)
                        echo "$input_join_final_2;$input_join_final;$number_session;$first_session" >> entry_join.tmp.$$
                done < username.tmp.$$
        done < uniq_mac.tmp.$$
}

function func_leave_final(){
        while read -r input_leave_final
        do
                grep "$input_leave_final" pre_entry_join.tmp.$$ | cut -d";" -f4| uniq > username.tmp.$$
                while read -r input_leave_final_2
                do
                        last_session=$(grep "$input_leave_final_2" pre_entry_leave.tmp.$$ | tail -n1 | cut -d";" -f1-2)
                        grep "$input_leave_final_2" pre_entry_leave.tmp.$$ | cut -d";" -f5-7 > username_leave.tmp.$$
                        time_final=0
                        rx_final=0
                        tx_final=0
                        while read -r input_leave_final_3
                        do
                                time_tmp=$(echo "$input_leave_final_3" | cut -d";" -f1)
                                rx_tmp=$(echo "$input_leave_final_3" | cut -d";" -f2)
                                tx_tmp=$(echo "$input_leave_final_3" | cut -d";" -f2)
                                time_final=$(echo "scale=2; $time_final + $time_tmp" | bc)
                                rx_final=$(echo "scale=0; $rx_final + $rx_tmp" | bc)
                                tx_final=$(echo "scale=0; $tx_final + $tx_tmp" | bc)
                        done < username_leave.tmp.$$
                        echo "$input_leave_final_2;$input_leave_final;$last_session;$time_final;$rx_final;$tx_final" >> entry_leave.tmp.$$
                done < username.tmp.$$
        done < uniq_mac.tmp.$$
}

function func_header_csv(){
        if [ -f "$csv_full_path" ]
        then
                line_orgin_tmp=$(wc -l "$csv_full_path" | cut -d" " -f1)
                line_orgin=$(echo "$line_orgin_tmp -  1" | bc)
                tail -n "$line_orgin" "$csv_full_path" > csv.tmp.$$
                echo "MAC-Adresse;Username;Anzahl Sessionen;Start Session;Ende Session;Verbindungdauer;Total RX;Total TX" > "$csv_full_path"
        else
                echo "MAC-Adresse;Username;Anzahl Sessionen;Start Session;Ende Session;Verbindungdauer;Total RX;Total TX" > "$csv_full_path"
        fi
}

function func_replace_join_csv(){
        while read -r input_replace_join_csv
        do
                username_new=$(echo "$input_replace_join_csv" | cut -d";" -f1)
                mac_new=$(echo "$input_replace_join_csv" | cut -d";" -f2)
                check_username=$(grep "$username_new" csv.tmp.$$)
                check_mac=$(grep "mac_new" csv.tmp.$$)
                if [ "$check_username" = "" -a "$check_mac" = "" ]
                then
                        echo "$input_replace_join_csv" >> join_final.tmp.$$
                else
                        session_new=$(echo "$input_replace_join_csv" | cut -d";" -f3)
                        session_old=$(cut -d";" -f3csv.tmp.$$)
                        session_temp=$(echo "$session_new + $session_old" | bc)
                        temp1=$(cut -d";" -f1-2 csv.tmp.$$)
                        temp2=$(cut -d";" -f4 csv.tmp.$$)
                        echo "$temp1;$session_temp;$temp2" >> join_final.tmp.$$
                fi
        done < entry_join.tmp.$$
}

function func_replace_leave_csv(){
        while read -r input_replace_leave_csv
        do
                username_new=$(echo "$input_replace_leave_csv" | cut -d";" -f1)
                mac_new=$(echo "$input_replace_leave_csv" | cut -d";" -f2)
                check_username=$(grep "$username_new" csv.tmp.$$)
                check_mac=$(grep "$mac_new" csv.tmp.$$)
                if [ "$check_username" = "" -a "$check_mac" = "" ]
                then
                        echo "$input_replace_leave_csv" >> leave_final.tmp.$$
                else
                        time_new=$(echo "$input_replace_leave_csv" | cut -d";" -f5)
                        time_old=$(grep "$username_new" csv.tmp.$$ | cut -d";" -f6)
                        rx_new=$(echo "$input_replace_leave_csv" | cut -d";" -f6)
                        rx_old=$(grep "$username_new" csv.tmp.$$ | cut -d";" -f7)
                        tx_new=$(echo "$input_replace_leave_csv" | cut -d";" -f7)
                        tx_old=$(grep "$username_new" csv.tmp.$$ | cut -d";" -f8)
                        time_temp=$(echo "$time_new + $time_old" | bc)
                        tx_temp=$(echo "$tx_new + $tx_old" | bc)
                        rx_temp=$(echo "$rx_new + $rx_old" | bc)
                        temp1=$(grep "$username_new" csv.tmp.$$ | cut -d";" -f1-2)
                        temp2=$(grep "$username_new" csv.tmp.$$ | cut -d";" -f4)
                        echo "$temp1;$temp2;$time_temp;$tx_temp;$rx_temp" >> leave_final.tmp.$$
                fi
        done < entry_leave.tmp.$$
}

function func_replace_csv(){
        while read -r input_replace_csv
        do
                mac_join=$(echo "$input_replace_csv" | cut -d";" -f1)
                username_join=$(echo "$input_replace_csv" | cut -d";" -f2)
                session=$(echo "$input_replace_csv" | cut -d";" -f3)
                time_join=$(echo "$input_replace_csv" | cut -d";" -f4)
                mac_search=$(grep "$mac_join" leave_final.tmp.$$ | cut -d";" -f1)
                username_search=$(grep "$username_join" leave_final.tmp.$$ | cut -d";" -f2)
                if [ "$mac_search" != "" -a "$username_search" != "" ]
                then
                        time_leave=$(grep "$mac_join;$username_join" leave_final.tmp.$$ | cut -d";" -f4)
                        tx_leave=$(grep "$mac_join;$username_join" leave_final.tmp.$$ | cut -d";" -f5)
                        rx_leave=$(grep "$mac_join;$username_join" leave_final.tmp.$$  | cut -d";" -f6)
                        echo "$username_join;$mac_join;$session;$time_join;$time_leave;$tx_leave;$rx_leave" >> "$csv_full_path"
                else
                        echo "$username_join;$mac_join;$session;$time_join;;;;" >> "$csv_full_path"
                fi
        done < join_final.tmp.$$
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