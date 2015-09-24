<?php

include 'connect.php';
$connection = new Connect();
$connectinfo = $connection->GetConnection();
$column = "groups_pending";
$currentrow = $connection->GetRow($connectinfo, 1, "863307073758034");
$notifraw = $connection->GetValue($connectinfo, 1, "863307073758034", "notification_raw");
$notiflist = explode(";", $notifraw);
$columnid = array_search($column, array_keys($currentrow));
print_r($columnid);
print_r($notiflist);
$notifremove = [];
$removeindex = [1];
$occurencecount = 0;
//NEED TO REMOVE FROM RAW AS WELL!
for ($b = 0; $b < count($notiflist); $b++) {
    if ($notiflist[$b] == $columnid) {
        if (in_array($occurencecount, $removeindex)) {
            $notifremove[] = $b;
        }
        $occurencecount++;
    }
}
print_r($notifremove);
for ($a = 0; $a < count($notifremove); $a++) {
    unset($notiflist[$notifremove[$a] - $a]);
}
/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

