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
                    array_push($currentarray, $value);
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

}