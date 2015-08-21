<?php

echo "Blah";
$currentarray = [["Name" => "Bob", "Age" => 21], ["Name" => "Bill", "Age" => 22], ["Name" => "Jason", "Age" => 23]];
$item = "Jason";
$unique = true;
$duplicateref = "Name";
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

