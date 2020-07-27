function Get-IcingaWindowsInformation()
{
    param (
        [string]$ClassName,
        $Filter
    );

    $Arguments = @{
        'ClassName' = $ClassName;
    }

    if ([string]::IsNullOrEmpty($Filter) -eq $FALSE) {
        $Arguments.Add(
            'Filter', $Filter
        );
    }

    if ((Get-Command 'Get-CimInstance' -ErrorAction SilentlyContinue)) {
        try {
            return (Get-CimInstance @Arguments -ErrorAction Stop)  
        } catch {
            $ErrorName    = $_.Exception.NativeErrorCode;
            $ErrorMessage = $_.Exception.Message;

            switch ($_.Exception.StatusCode) {
                # InvalidClass
                5 {
                    Exit-IcingaThrowException -ExceptionType 'Input' -ExceptionThrown $IcingaExceptions.Inputs.CimClassNameUnknown -CustomMessage $ClassName -Force;
                };
                # TODO: Find error Id for permission errors
                # Permission error
                #x {
                #    Exit-IcingaThrowException -ExceptionType 'Permission' -ExceptionThrown $IcingaExceptions.Permission.CimInstance -CustomMessage $ClassName -Force;
                #};
                # All other errors
                default {
                    Exit-IcingaThrowException -ExceptionType 'Custom' -InputString $ErrorMessage -CustomMessage ([string]::Format('CimInstanceUnhandledError: Class "{0}": Error "{1}"', $ClassName, $ErrorName)) -Force;
                }
            }
        }
    }

    if ((Get-Command 'Get-WmiObject' -ErrorAction SilentlyContinue)) {
        try {
            return (Get-WmiObject @Arguments -ErrorAction Stop)  
        } catch {
            $ErrorName    = $_.CategoryInfo.Category;
            $ErrorMessage = $_.Exception.Message;

            Exit-IcingaThrowException -ExceptionType 'Custom' -InputString $ErrorMessage -CustomMessage ([string]::Format('WmiObjectUnhandledError: Class "{0}": Error "{1}"', $ClassName, $ErrorName)) -Force;
        }
    }

    # Exception
    Exit-IcingaThrowException -ExceptionType 'Custom' -InputString 'Failed to fetch Windows information by using CimInstance or WmiObject. Both commands are not present on the system.' -CustomMessage ([string]::Format('CimWmiUnhandledError: Class "{0}"', $ClassName)) -Force;
}