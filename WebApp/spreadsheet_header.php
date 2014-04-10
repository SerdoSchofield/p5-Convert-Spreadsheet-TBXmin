<?php

    // convert an uploaded file from TBX-Basic to TBX-Min

    $temp_file_name = $_FILES['upload']['tmp_name'];
    $source = $_POST['source'];
    $target = $_POST['target'];
	$timestamp = $_POST['timestamp'];
	$license = $_POST['license'];
	$creator = $_POST['creator'];
	$description = $_POST['description'];
	$directionality = $_POST['directionality'];
	$subject = $_POST['subject'];
	$dict_id = $_POST['dict_id'];
    if ($_FILES["upload"]["error"] > 0)
    {
        echo "<p>Error: " . $_FILES["file"]["error"] . "</p>\n";
    }
    $out_file_name = $temp_file_name . '.log';
    $perl = 'perl';
    $perl_lib = '-I TBX-Min-0.06/lib -I Convert-Spreadsheet-TBXmin-0.01/lib';
    $script = 'Convert-Spreadsheet-TBXmin-0.01/bin/spreadsheet2tbx';
    #set this to true when you put it on gevterm.
    $onServer = true;
    if($onServer){
        $perl_lib .= ' -I /home2/gevtermn/perl5/lib/perl5';
    }
    # stderr gets sent to file in case it's needed
    $rerouteIO = "2>$out_file_name";
    # TODO: probably don't need to print to file
    # and then serve the file...
    $command = "$perl $perl_lib $script " .
        escapeshellarg($temp_file_name) . ' ' .
        escapeshellarg($source) . ' ' .
        escapeshellarg($target) . ' ' .
		escapeshellarg($timestamp) . ' ' .
		escapeshellarg($license) . ' ' .
		escapeshellarg($creator) . ' ' .
		escapeshellarg($description) . ' ' .
		escapeshellarg($directionality) . ' ' .
		escapeshellarg($subject) . ' ' .
		escapeshellarg($dict_id) . ' ' .
        $rerouteIO;
    $ret_val = 0;
    // echo $command;
    exec($command, $printed_output, $ret_val);
    if(($ret_val != 0) || (!file_exists($out_file_name)) ){
        header('HTTP/1.1 400 Bad Request');
        ob_clean();
        flush();
        readfile($out_file_name);
    }else{
        # download a file with same name as upload
        $down_file_name = $_FILES['upload']['name'];
        header("Content-type: application/octet-stream");
        header('Content-Disposition: attachment; filename="' .
            $down_file_name . '"');
        header('Content-Transfer-Encoding: binary');
        ob_clean();
        flush();
        foreach($printed_output as $line) {
            print "$line\n";
        }
    }
?>
