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

##########################################################################################

#   Anpassbare Variablen

log_location="/var/log/192.168.0.8/syslog.log"    # Speicherpfad der Syslogdatei
ssid="Test_Gast"    # zu Anlalysierende SSID
databas="csv"    # Speichervariante der Enddaten. Mögliche Werte: csv, sql
mac_only="false"    # Nur MAC-Adressen speichern, falls der Wert "false" ist werden auch die Benutzernamen erfasst.

#########################################################################################

#   Funktionen

function func_analyse(){
        cat $log_location | grep "$ssid" | grep "User" > log_redu.tmp
        while read input
        do
                echo ""
        done < log_redu.tmp
}

#########################################################################################

#   Programm
func_analyse
exit
