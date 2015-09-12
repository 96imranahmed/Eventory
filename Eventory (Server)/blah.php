<?php
$currentarray = unserialize('a:1:{i:1;a:6:{s:8:"sourceid";s:17:"10200598208075829";s:4:"date";i:1441667753;s:4:"type";i:1;s:4:"text";s:26:"Lisa invited you to join 2";s:6:"isread";i:0;s:4:"data";s:10:"groupid:15";}}');
$item = "groupid:".strval(15);
$duplicateref = "data";
$removeindex = [];
for ($i = 0; $i < count($currentarray); $i++) {
    $check = $currentarray[1];
    if ($item == $check[$duplicateref]) {
        $removeindex[] = 1;
    }
}
for ($j = 0; $j < count($removeindex); $j++) {
    unset($currentarray[$removeindex[$j]-$j]);
}
echo serialize($currentarray);
/* 
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

