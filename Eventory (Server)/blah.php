<?php
$currentarray = unserialize("a:2:{i:0;a:6:{s:8:\"sourceid\";s:17:\"10200598208075829\";s:4:\"date\";i:1440280906;s:4:\"type\";i:1;s:4:\"text\";s:29:\"Lisa invited you to join Blah\";s:6:\"isread\";i:0;s:4:\"data\";s:10:\"groupid:11\";}i:1;a:6:{s:8:\"sourceid\";s:17:\"10200598208075829\";s:4:\"date\";i:1440280993;s:4:\"type\";i:1;s:4:\"text\";s:28:\"Lisa invited you to join Bro\";s:6:\"isread\";i:0;s:4:\"data\";s:10:\"groupid:12\";}}");
$groupid = 11;
$item = "groupid:".strval($groupid);
$unique = true;
$duplicateref = "data";
$removeindex = [];
for ($i = 0; $i < count($currentarray); $i++) {
    $check = $currentarray[$i];
    if ($item == $check[$duplicateref]) {
        $removeindex[] = $i;
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

