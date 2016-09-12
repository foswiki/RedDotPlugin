# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2005-2016 Michael Daum http://michaeldaumconsulting.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at 
# http://www.gnu.org/copyleft/gpl.html
#
package Foswiki::Plugins::RedDotPlugin::Core;

use strict;
use warnings;

use Foswiki::Func ();
use Foswiki::Plugins ();
use Foswiki::Plugins::JQueryPlugin ();
use Foswiki::Plugins::JQueryPlugin::Plugin ();

our @ISA = qw( Foswiki::Plugins::JQueryPlugin::Plugin );

use constant TRACE => 0;    # toggle me

###############################################################################
# static
sub writeDebug {
  #Foswiki::Func::writeDebug("- RedDotPlugin - " . $_[0]) if TRACE;
  print STDERR "- RedDotPlugin - " . $_[0] . "\n" if TRACE;
}

###############################################################################
sub new {
  my $class = shift;

  my $this = bless($class->SUPER::new( 
    name => 'RedDot',
    version => '4.00',
    author => 'Michael Daum',
    homepage => 'http://foswiki.org/Extensions/RedDotPlugin',
    puburl => '%PUBURLPATH%/%SYSTEMWEB%/RedDotPlugin',
    documentation => '%SYSTEMWEB%.RedDotPlugin',
    javascript => ['reddot.js'],
    css => ['reddot.css'],
    dependencies => ['livequery', 'hoverintent', 'JQUERYPLUGIN::FOSWIKI'], 
    currentAction => undef,
    counter => 0,
  ), $class);

  return $this;
}

###############################################################################
sub handleRedDot {
  my ($this, $session, $params, $theTopic, $theWeb) = @_;

  #writeDebug("called handleRedDot($theWeb, $theTopic), parms=".$params->stringify);

  return '' unless Foswiki::Func::getContext()->{view};

  my $theWebTopics = $params->{_DEFAULT} || "$theWeb.$theTopic";
  my $theRedirect = $params->{redirect};
  my $theText = $params->{text};
  my $theStyle = $params->{style} || '';
  my $theClass = $params->{class} || '';
  my $theIcon = $params->{icon} || 'fa-pencil';
  my $theGrant = $params->{grant} || '.*';
  my $theTitle = $params->{title};
  my $theAnimate = Foswiki::Func::isTrue($params->{animate}, 1);
  my $theAction = $params->{action};
  my $theTemplate = $params->{template};
  my $theParent = $params->{parent};

  my $mode = 'redDotIconMode';
  if ($theText) {
    if (defined $theText) {
      $mode = 'redDotTextMode';
    } else {
      $mode = 'redDotDefaultMode';
      $theText = '.';
    }
    $theText = "$theText";
  } else {
    $theText = '%JQICON{"' . $theIcon . '" format="<img src=\'$iconPath\' width=\'16\' height=\'16\' class=\'$iconClass\' $iconAlt/>"}%';
  }
  if ($theAnimate) {
    $mode .= ' redDotAnimated';
  }

  my $baseWeb = $session->{webName};
  my $baseTopic = $session->{topicName};

  my $query = Foswiki::Func::getCgiQuery();
  unless ($theRedirect) {
    my $redirectPref = Foswiki::Func::getPreferencesValue("REDDOT_REDIRECT");
    if ($redirectPref) {
      $redirectPref = Foswiki::Func::expandCommonVariables($redirectPref);
      my ($redirectWeb, $redirectTopic) = Foswiki::Func::normalizeWebTopicName($baseWeb, $redirectPref);
      $theRedirect = Foswiki::Func::getScriptUrl($redirectWeb, $redirectTopic, 'view');
    } else {
      my $queryString = $query->query_string;

      # SMELL: double quotes, even encoded truncate the redirectto.
      # so we double encode them
      $queryString =~ s/\%22/\%2522/g;

      $theRedirect = Foswiki::Func::getScriptUrl($baseWeb, $baseTopic, 'view') . '?' . $queryString;
    }
    $theRedirect .= "%23reddot".$this->{counter};
  }

  # find the first webtopic that we have access to
  my $thisWeb;
  my $thisTopic;
  my $hasEditAccess = 0;
  my $wikiName = Foswiki::Func::getWikiName();

  foreach my $webTopic (split(/\s*,\s*/, $theWebTopics)) {
    #writeDebug("testing webTopic=$webTopic");

    ($thisWeb, $thisTopic) = Foswiki::Func::normalizeWebTopicName($baseWeb, $webTopic);
    $thisWeb =~ s/\//\./go;

    if (Foswiki::Func::topicExists($thisWeb, $thisTopic)) {
      #writeDebug("checking access on $thisWeb.$thisTopic for $wikiName");
      $hasEditAccess = Foswiki::Func::checkAccessPermission("CHANGE", $wikiName, undef, $thisTopic, $thisWeb);
      if ($hasEditAccess) {
        $hasEditAccess = 0 unless $wikiName =~ /$theGrant/;
        # SMELL: use the users and groups functions to check
        # if we are in theGrant
      }
      if ($hasEditAccess) {
        #writeDebug("granted");
        last;
      }
    }
  }

  if (!$hasEditAccess) {
    return '';
  }

  #writeDebug("rendering red dot on $thisWeb.$thisTopic for $wikiName");

  my %params = ();
  $params{t} = time();
  $params{action} = $theAction if defined $theAction;
  $params{template} = $theTemplate if defined $theTemplate;
  $params{redirectto} = $theRedirect if $theRedirect ne "$thisWeb.$thisTopic";

  # red dotting
  my $result = "<span class='redDot $mode $theClass' id='reddot" . ($this->{counter}++) . "' ";

  my $url = Foswiki::Func::getScriptUrl($thisWeb, $thisTopic, 'edit', %params);
  $url =~ s/%2523reddot/%23reddot/g; # revert double encoding of # anchor

  $result .= "data-parent='$theParent' " if defined $theParent;
  $result .= "style='$theStyle' " if $theStyle;
  $result .= "><a href='$url' ";

  if ($theTitle) {
    $result .= "title='%ENCODE{\"$theTitle\" type=\"entity\"}%'";
  } else {
    $result .= "title='Edit&nbsp;<nop>$thisWeb.$thisTopic'";
  }
  $result .= ">$theText</a></span>";

  #writeDebug("done handleRedDot");

  return $result;
}

1;
