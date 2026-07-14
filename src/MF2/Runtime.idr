module MF2.Runtime

-- Read this runtime in dependency order:
--   Types -> Environment -> Handlers -> Selection -> Resolution -> Format.
-- The facade keeps application imports stable while each phase remains small
-- enough to study independently.
import public MF2.Runtime.Types
import public MF2.Runtime.Environment
import public MF2.Runtime.Handlers
import public MF2.Runtime.Selection
import public MF2.Runtime.Resolution
import public MF2.Runtime.Format

%default total
