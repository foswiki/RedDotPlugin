# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2005-2024 Michael Daum http://michaeldaumconsulting.com
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
package Foswiki::Plugins::RedDotPlugin;

use strict;
use warnings;

use Foswiki::Func ();
use Foswiki::Plugins ();
use Foswiki::Plugins::JQueryPlugin ();

our $VERSION = '4.20';
our $RELEASE = '%$RELEASE%';
our $NO_PREFS_IN_TOPIC = 1;
our $SHORTDESCRIPTION = 'Quick-edit links';
our $LICENSECODE = '%$LICENSECODE%';
our $core;

sub initPlugin {

  Foswiki::Plugins::JQueryPlugin::registerPlugin('reddot', 'Foswiki::Plugins::RedDotPlugin::Core');

  $core = undef;
  
  Foswiki::Func::registerTagHandler('REDDOT', sub {
    $core = Foswiki::Plugins::JQueryPlugin::createPlugin('reddot') unless defined $core;

    return $core->handleRedDot(@_) if $core;
    return '';
  });

  return 1;
}

1;
