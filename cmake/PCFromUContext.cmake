include(CheckCSourceCompiles)
include(CheckIncludeFile)

macro(pc_from_ucontext variable)
    set(HAVE_${variable} OFF)
    check_include_file("ucontext.h" HAVE_UCONTEXT_H)
    if(EXISTS /etc/redhat-release)
        set(redhat7_release_pattern "Red Hat Linux release 7")
        file(STRINGS /etc/redhat-release redhat_release_match
             LIMIT_COUNT 1
             REGEX ${redhat7_release_pattern})
        if(redhat_release_match MATCHES ${redhat7_release_pattern})
            set(HAVE_SYS_UCONTEXT_H OFF)
        else()
            check_include_file("sys/ucontext.h" HAVE_SYS_UCONTEXT_H)
        endif()
    else()
        check_include_file("sys/ucontext.h" HAVE_SYS_UCONTEXT_H)
    endif()
    check_include_file("cygwin/signal.h" HAVE_CYGWIN_SIGNAL_H)

    set(pc_fields
        "uc_mcontext.gregs[REG_PC]"  # Solaris x86 (32 + 64 bit)
        "uc_mcontext.gregs[REG_EIP]"  # Linux (i386)
        "uc_mcontext.gregs[REG_RIP]"  # Linux (x86_64)
        "uc_mcontext.sc_ip"  # Linux (ia64)
        "uc_mcontext.pc"  # Linux (mips)
        "uc_mcontext.uc_regs->gregs[PT_NIP]"  # Linux (ppc)
        "uc_mcontext.psw.addr"  # Linux (s390)
        "uc_mcontext.gregs[R15]"  # Linux (arm old [untested])
        "uc_mcontext.arm_pc"  # Linux (arm arch 5)
        "uc_mcontext.gp_regs[PT_NIP]"  # Suse SLES 11 (ppc64)
        "uc_mcontext.mc_eip"  # FreeBSD (i386)
        "uc_mcontext.mc_rip"  # FreeBSD (x86_64 [untested])
        "uc_mcontext.__gregs[_REG_EIP]"  # NetBSD (i386)
        "uc_mcontext.__gregs[_REG_RIP]"  # NetBSD (x86_64)
        "uc_mcontext->ss.eip"  # OS X (i386, <=10.4)
        "uc_mcontext->__ss.__eip"  # OS X (i386, >=10.5)
        "uc_mcontext->ss.rip"  # OS X (x86_64)
        "uc_mcontext->__ss.__rip"  # OS X (>=10.5 [untested])
        "uc_mcontext->ss.srr0"  # OS X (ppc, ppc64 [untested])
        "uc_mcontext->__ss.__srr0"# OS X (x86, >=10.5 [untested])
        "uc_mcontext->__ss.__pc")  # OS X (arm64, >=10.5 [untested])

    set(CMAKE_REQUIRED_DEFINITIONS -D_GNU_SOURCE=1)
    if(HAVE_CYGWIN_SIGNAL_H)
        set(_inc "cygwin/signal.h")
    elseif(HAVE_SYS_UCONTEXT_H)
        set(_inc "sys/ucontext.h")
    elseif(HAVE_UCONTEXT_H)
        set(_inc "ucontext.h")
    endif()
    foreach(pc_field IN LISTS pc_fields)
        string(MAKE_C_IDENTIFIER ${pc_field} pc_field_id)
        check_c_source_compiles(
            "#include <${_inc}>\nint main() { ucontext_t u; return u.${pc_field} == 0; }"
            HAVE_${pc_field_id})
        if(HAVE_${pc_field_id})
            set(HAVE_${variable} ON)
            set(${variable} ${pc_field})
            break()
        endif()
    endforeach()
endmacro()
