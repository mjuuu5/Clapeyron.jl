                 +-----------------------+
                 |      C / C++ User     |
                 +-----------+-----------+
                             |
                   create_model(json)
                             |
                             v
                  +--------------------+
                  |  C API Wrapper DLL |
                  +--------------------+
                             |
                      jl_call_create()
                             |
                             v
                +------------------------+
                | Julia Wrapper Module   |
                |  JSON -> Model Parser  |
                +------------------------+
                             |
                    build Clapeyron model
                             |
                             v
                 Clapeyron.AbstractModel
                             |
                  return opaque Handle


This design favors:

- ABI stability
- Extendability