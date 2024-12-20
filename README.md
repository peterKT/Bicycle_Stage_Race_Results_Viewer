# Bicycle_Stage_Race_Results_Viewer, Version 4.0
(Due to a change in the way bike race results are made available, this code is temporarily unable to work properly. It depends on the results being presented on Web sites in a format such that a simple cut-and-paste can capture all details as text strings. Unfortunately the updated presentation replaces the nationality of riders, previously expressed simply as a text string, with a link to a GIF showing the national flag. So I need to include a bit of code that will translate the GIF back into text. Hmmm. Anyway, I will leave this README up so it can be used again, once the correction is made. This opening paragraph is dated March 2, 2024.)

With these tools, publicly available GC (general classification) results for major bicycle stage races like the Tour de France can be re-formatted to display interesting details about movement up and down the standings as they occur--sometimes dramatically--each day. The user will need to copy and paste such results into text files (not too hard!). The rest is handled by command-line perl scripts that quickly rip through the text files and prepare the results for permanent viewing. Requires Linux, Perl, MySQL and an office app like LibreOffice for making the text files.

This Version 4.0 introduces major changes. I'm not exactly sure why but everything stopped working correctly. I think, but don't know, it had something to do with the way MariaDB uses character sets. For some reason, while I had thought I was using utf8 before, now everthing is in some set called utf8mb4. That messes everything up. I had to go back and correct some stuff to get it to work again. On the bright side, one fix I introduced in the script that outputs everything--binmode STDOUT, ":utf8"; -- actually helped by eliminating the spacing problem in output whenever diacritics appeared. Those steps are no longer needed and have been taken out.

See the Wiki for details on using.
