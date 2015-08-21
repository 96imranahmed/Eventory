<?php

class Connect {

    public $dbo;

//Setups an initial connection
    public function GetConnection() {
        try {
            $ServerName = "localhost";
            $database = "acaveex1_Acavee";
            $username = "acaveex1_96imran";
            $password = "8ch12enpl!";
            $dbo = new PDO('mysql:host=' . $ServerName . ';dbname=' . $database, $username, $password);
            $dbo->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
            $dbo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            return $dbo;
        } catch (PDOException $e) {
            return $e->getMessage();
        }
    }

//Updates a list array with a new entry
    public function AddtoList($pdo, $tablename, $id, $column, $value) {
        $prepsql = $pdo->prepare("SELECT * FROM $tablename WHERE id = '$id' LIMIT 1");
        $prepsql->execute();
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        if ($current == null) {
            $current = $value;
        } else {
            if ($current == "") {
                $current = $value;
            } else {
                $currentarray = explode(";", $current);
                if (in_array($value, $currentarray)) {
                    
                } else {
                    $currentarray[] = $value;
                    $current = implode(";", $currentarray);
                }
            }
        }
        $postsql = $pdo->prepare("UPDATE $tablename SET $column='$current' WHERE id=$id");
        $postsql->execute();
    }

//Removes an entry from a list array
    public function RemovefromList($pdo, $tablename, $id, $column, $value) {
        $prepsql = $pdo->prepare("SELECT * FROM $tablename WHERE id = '$id' LIMIT 1");
        $prepsql->execute();
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        if ($current == null || $current == "") {
            $postsql = $pdo->prepare("UPDATE $tablename SET $column = null WHERE id=$id");
            $postsql->execute();
        } else {
            $currentarray = explode(";", $current);
            if (($key = array_search($value, $currentarray)) !== false) {
                unset($currentarray[$key]);
            } else {
                
            }
            if (count($currentarray) < 1) {
                $current = null;
                $postsql = $pdo->prepare("UPDATE $tablename SET $column = null WHERE id=$id");
                $postsql->execute();
            } else {
                $current = implode(';', $currentarray);
                $postsql = $pdo->prepare("UPDATE $tablename SET $column='$current' WHERE id=$id");
                $postsql->execute();
            }
        }
    }

//Checks if a value is in list
    public function ListCheck($pdo, $tablename, $id, $column, $value) {
        $prepsql = $pdo->prepare("SELECT * FROM $tablename WHERE id = '$id' LIMIT 1");
        $prepsql->execute();
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        if ($current == null || $current == "") {
            if ($value == null || $value == "") {
                return true;
            } else {
                return false;
            }
        } else {
            $currentarray = explode(";", $current);
            if (($key = array_search($value, $currentarray)) !== false) {
                return true;
            } else {
                return false;
            }
        }
    }

//Checks if supplied token matches values stored in database
    public function Verify($pdo, $id, $token) {
        $prepsql = $pdo->prepare("SELECT * FROM Profiles WHERE id = '$id' LIMIT 1");
        $prepsql->execute();
        $currentrow = $prepsql->fetch();
        $current = preg_replace("/[^a-zA-Z0-9]+/", "", $currentrow["token"]);
        $token = preg_replace("/[^a-zA-Z0-9]+/", "", $token);
        if ($current == null || $current == "") {
            return false;
        } else {
            if (strcmp($token, $current) == 0) {
                return true;
            } else {
                return false;
            }
        }
    }

//Checks if initial supplied token is valid and if so returns True
    public function TokenVerify($id, $token) {
        $result = @file_get_contents("https://graph.facebook.com/me?access_token=$token");
        if (FALSE === $result) {
            return false;
        } else {

            if (strpos($result, $id) !== false) {
                return true;
            } else {
                return false;
            }
        }
    }

//Get the Name property for a given ID and type
    public function GetNamebyId($pdo, $id, $type) {
        if ($type == 0) {
            //Get name of a person
            $prepsql = $pdo->prepare("SELECT * FROM Profiles WHERE id = '$id' LIMIT 1");
            $prepsql->execute();
            $currentrow = $prepsql->fetch();
            return($currentrow["name"]);
        } elseif ($type == 1) {
            //Get name of group
            $prepsql = $pdo->prepare("SELECT * FROM Groups WHERE id = '$id' LIMIT 1");
            $prepsql->execute();
            $currentrow = $prepsql->fetch();
            return($currentrow["name"]);
        } else {
            return ("Error - invalid type request");
        }
    }

//Get the first ID of an entry
    public function GetFirstEntry($pdo, $tablename, $id, $column) {
        $prepsql = $pdo->prepare("SELECT * FROM $tablename WHERE id = '$id' LIMIT 1");
        $prepsql->execute();
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        if ($current == null || $current == "") {
            return null;
        } else {
            return explode(";", $current)[0];
        }
    }

//Get value at a certain point
    public function GetValue($pdo, $tablename, $id, $column) {
        $prepsql = $pdo->prepare("SELECT * FROM $tablename WHERE id = '$id' LIMIT 1");
        $prepsql->execute();
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        return $current;
    }

//Get row at a certain point
    public function GetRow($pdo, $tablename, $id) {
        $prepsql = $pdo->prepare("SELECT * FROM $tablename WHERE id = '$id' LIMIT 1");
        $prepsql->execute();
        $currentrow = $prepsql->fetch();
        return $currentrow;
    }

    public function UpdateScore($pdo, $id, $change) {
        $prepsql = $pdo->prepare("SELECT * FROM Profiles WHERE id = '$id' LIMIT 1");
        $prepsql->execute();
        $currentrow = $prepsql->fetch();
        $current = intval($currentrow["score"]) + intval($change);
        if ($current < 0) {
            $current = 0;
        }
        $postsql = $pdo->prepare("UPDATE Profiles SET score='$current' WHERE id=$id");
        $postsql->execute();
    }

    //Increments unseen notification count
    public function IncrementNotification($pdo, $id) {
        $prepsql = $pdo->prepare("SELECT * FROM Notifications WHERE id = '$id' LIMIT 1");
        $prepsql->execute();
        $currentrow = $prepsql->fetch();
        $current = intval($currentrow["numberunseen"]) + 1;
        $postsql = $pdo->prepare("UPDATE Notifications SET numberunseen='$current' WHERE id=$id");
        $postsql->execute();
    }

    //Decrements unseen notification count
    public function DecrementNotification($pdo, $id) {
        $prepsql = $pdo->prepare("SELECT * FROM Notifications WHERE id = '$id' LIMIT 1");
        $prepsql->execute();
        $currentrow = $prepsql->fetch();
        $current = intval($currentrow["numberunseen"]) - 1;
        if ($current < 0) {
            $current = 0;
        }
        $postsql = $pdo->prepare("UPDATE Notifications SET numberunseen='$current' WHERE id=$id");
        $postsql->execute();
    }

    //Add dictionary to list
    public function AddItemtoList($pdo, $tablename, $id, $column, $value, $duplicateref) {
        $prepsql = $pdo->prepare("SELECT * FROM $tablename WHERE id = '$id' LIMIT 1");
        $prepsql->execute();
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        if ($current == null || $current == "") {
            $currentarray = [$value];
            $current = serialize($currentarray);
            if ($tablename == "Notifications") {
                $this->IncrementNotification($pdo, $id);
            }
        } else {
                $currentarray = unserialize($current);
                $unique = true;
                for ($i = 0; $i < count($currentarray); $i++) {
                    $loop = $currentarray[$i];
                    if ($loop[$duplicateref] == $value[$duplicateref]) {
                        $unique = false;
                    }
                }
                if ($unique) {
                    $currentarray[] = $value;
                    if ($tablename == "Notifications") {
                        $this->IncrementNotification($pdo, $id);
                    }
                }
                $current = serialize($currentarray);
        }
        $postsql = $pdo->prepare("UPDATE $tablename SET $column='$current' WHERE id=$id");
        $postsql->execute();
    }

    //Remove item from list
    public function RemoveItemfromList($pdo, $tablename, $id, $column, $item, $duplicateref) {
        $prepsql = $pdo->prepare("SELECT * FROM $tablename WHERE id = '$id' LIMIT 1");
        $prepsql->execute();
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        if ($current == null || $current == "") {
            $postsql = $pdo->prepare("UPDATE $tablename SET $column = null WHERE id=$id");
            $postsql->execute();
        } else {
            $currentarray = unserialize($current);
            $removeindex = [];
            for ($i = 0; $i < count($currentarray); $i++) {
                $check = $currentarray[$i];
                if ($item == $check[$duplicateref]) {
                    $removeindex[] = $i;
                }
            }
            for ($j = 0; $j < count($removeindex); $j++) {
                unset($currentarray[$removeindex[$j]-$j]);
                if ($tablename == "Notifications") {
                    $this->DecrementNotification($pdo, $id);
                }
            }
            if (count($currentarray) < 1) {
                $current = null;
                $postsql = $pdo->prepare("UPDATE $tablename SET $column = null WHERE id=$id");
                $postsql->execute();
            } else {
                $current = serialize($currentarray);
                $postsql = $pdo->prepare("UPDATE $tablename SET $column='$current' WHERE id=$id");
                $postsql->execute();
            }
        }
    }

    //Set read receipt
    public function SetRead($pdo, $id, $column) {
        $prepsql = $pdo->prepare("SELECT * FROM Notifications WHERE id = '$id' LIMIT 1");
        $prepsql->execute();
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        if ($current == null || $current == "") {
            $postsql = $pdo->prepare("UPDATE Notifications SET $column = null WHERE id=$id");
            $postsql->execute();
        } else {
            $currentarray = unserialize($current);
            if (is_array($currentarray)) {
                if ($currentarray["isread"] == null) {
                    for ($i = 0; $i < count($currentarray); $i++) {
                        $loop = $currentarray[i];
                        if ($loop["isread"] == 0) {
                            $loop["isread"] = 1;
                            $this->DecrementNotification($pdo, $id);
                        }
                        $currentarray[i] = $loop;
                    }
                } else {
                    if ($currentarray["isread"] == 0) {
                        $currentarray["isread"] = 1;
                        $this->DecrementNotification($pdo, $id);
                    }
                }
            }
            $current = serialize($currentarray);
            $postsql = $pdo->prepare("UPDATE Notifications SET $column='$current' WHERE id=$id");
            $postsql->execute();
        }
    }

}
