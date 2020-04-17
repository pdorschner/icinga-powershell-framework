<#
.SYNOPSIS
   Fetch the current network route configuration of our Windows host
.DESCRIPTION
   Newer Windows systems provide a Cmdlet 'Get-NetRoute' for fetching the
   network route configurations. Older systems however do not provide this
   and we have to manually fetch the data over WMI. This Cmdlet will check
   if Get-NetRoute is avaiable and use it if present, otherwise it will
   fallback to WMI automatically and return an array of PSObjects with
   data identical for your needs for easier integration
.FUNCTIONALITY
   This Cmdlet will return the current configuration network routing table
.EXAMPLE
   PS>Get-IcingaNetworkRoutes
.OUTPUTS
   System.Array
.LINK
   https://github.com/Icinga/icinga-powershell-framework
.NOTES
#>

function Get-IcingaNetworkRoutes()
{
    # If are using newer versions of Windows, we can simply use 'Get-NetRoute'
    if ($null -ne (Get-Command 'Get-NetRoute' -ErrorAction SilentlyContinue)) {
        return (Get-NetRoute);
    }

    # Older versions of Windows do not support this, so we have to build our own 'Get-NetRoute'
    # handling by fetching the routing table over WMI. We will however only support IPv4 in
    # this case
    $NetworkRoutes = Get-WmiObject -Class Win32_IP4RouteTable;
    [array]$Routes = @();

    foreach ($route in $NetworkRoutes) {
        # At first we need to fetch the Mask we are going to use
        $NetworkMask = $route.Description.Replace(' ', '').Split('-')[1];

        # Convert our mask
        $MaskToBit = 0;
        $NetworkMask -split '\.' | ForEach-Object {
            $MaskToBit = $MaskToBit * 256 + [Convert]::ToInt64($_);
        }

        # Get our CIDR to know which interface might be responsible
        $CIDR = [Convert]::ToString($MaskToBit, 2).IndexOf('0');
        if ($CIDR -eq -1) {
            $CIDR = 32;
        }

        # Build our destination prefix
        $DestinationPrefix = [string]::Format(
            '{0}/{1}',
            $route.Destination,
            $CIDR
        );

        # Add a custom PowerShell object matching our the data of Get-NetRoute for our requirements
        $NetworkRoute = New-Object -TypeName PSObject;
        $NetworkRoute | Add-Member -MemberType NoteProperty -Name ifIndex           -Value $route.InterfaceIndex;
        $NetworkRoute | Add-Member -MemberType NoteProperty -Name DestinationPrefix -Value $DestinationPrefix;
        $NetworkRoute | Add-Member -MemberType NoteProperty -Name NextHop           -Value $route.NextHop;

        # Add our route to the array
        $Routes += $NetworkRoute
    }

    return $Routes;
}
