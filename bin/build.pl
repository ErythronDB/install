#########################################################################
#########################################################################
#
# A convenience wrapper around ant.  Simplifies the input args.
#
#########################################################################
#########################################################################


use strict;
use Cwd 'realpath'; 

my @projects = ("AllGenes", "AnnotatorsInterface", "Annotator", "CBIL", "DJob", "DoTS", "GUS", "ParaDBs", "PlasmoDB","RAD","ApiDots", "TESS");

my @whats = ("install", "webinstall");

my $projectHome = $ENV{PROJECT_HOME};

if (!$projectHome) {
  if (! (-e "build.pl" && -d "../install")) {
    print "Error: Please either define the \$PROJECT_HOME environment variable or run install from the install/ directory\n";
    exit 1;
  }
  $projectHome = realpath("..");
} 

my ($project, $component, $doWhat, $targetDir, $append, $clean, $skipJava, $doCheckout, $tag, $webPropFile, $returnErrStatus) = &parseArgs(@ARGV);

$| = 1;

my $cmd = "ant -f $projectHome/install/build.xml $doWhat -Dproj=$project -DtargetDir=$targetDir -Dcomp=$component -DprojectsDir=$projectHome $clean $skipJava $append $webPropFile $tag -logger org.apache.tools.ant.NoBannerLogger ";


# if not returning error status, then can pretty up output by keeping
# only lines with bracketed ant target name (ie, ditch its commentary).
# the grep, however, frustrates accurate status reporting
if (!$returnErrStatus) {
  $cmd .= " | grep ']'";
}

print "\n$cmd\n\n";
system($cmd);

# only valid if $returnErrStatus is set
my $status = $? >>8;
exit($status);


############################ subroutines ####################################

sub parseArgs {

    my $project = shift @ARGV;
    my $component; 

    if ($project =~ /(\w+)(\/\w+)/ ) {
	$project = $1;
	$component = $2;
    }
    my $doWhat = shift @ARGV;

    if ($doWhat eq "release") {
      &usage unless (scalar(@ARGV) == 1);
      my $tag = "-Dtag=$ARGV[0]";
      return ($project, '', $doWhat, '', '', '', '', '', $tag);
    }

    my $targetDir;
    if ($ENV{GUS_HOME} && (!$ARGV[0] || $ARGV[0] =~ /^-/)) {
	$targetDir = $ENV{GUS_HOME};
    } else {
	$targetDir = shift @ARGV;
    }

    &usage() unless $project && grep(/$project/, @projects);
    &usage() unless $doWhat && grep(/$doWhat/, (@whats, "release"));
    &usage() unless $targetDir;


    my ($append, $clean, $skipJava, $doCheckout, $version, $webPropFile);
    if ($ARGV[0] eq "-append") {
	shift @ARGV;
        $append = "-Dappend=true";
    } 

    if ($ARGV[0] eq "-clean") {
        shift @ARGV;
        $clean = "-Dclean=true";
    }
   
    if ($ARGV[0] eq "-returnErrStatus") {
        shift @ARGV;
        $returnErrStatus = 1;
    }
   
    if ($ARGV[0] eq "-skipJavaCompiling") {
	shift @ARGV;
	$skipJava = "-DskipJavaCompiling=true";
    }

    if ($ARGV[0] eq "-webPropFile") {
        shift @ARGV;
	my $wpFile = shift @ARGV;
	$webPropFile = "-propertyfile $wpFile -DwebPropFile=$wpFile";
    }

    if ($doCheckout = $ARGV[0]) {
	&usage() if ($doCheckout ne "-co");
	$version = $ARGV[1];
    }

    return ($project, $component, $doWhat, $targetDir, $append, $clean, $skipJava, $doCheckout, $version, $webPropFile, $returnErrStatus);
}

sub usage {
    my $projects = join("|", @projects);
    my $whats = join("|", @whats);

    print 
"
usage: 
  build $projects\[/componentname]  $whats  targetDir -append [-skipJavaCompiling] [-webPropFile propfile] [-co [version]] 
  build $projects release version

";
    exit 1;
}


