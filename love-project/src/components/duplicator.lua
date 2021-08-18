local component = {
    'duplicator',
    function(x)
        return {
            magnitude = x,
            used      = false
        }
    end
}

return component