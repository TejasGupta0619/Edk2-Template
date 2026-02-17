#include <PiDxe.h>
#include <Protocol/SmmCpu.h>
#include <Protocol/SmmBase2.h>
#include <Library/BaseLib.h>
#include <Library/DebugLib.h>
#include <Library/MmServicesTableLib.h>
#include <IndustryStandard/Q35MchIch9.h>
#include <Protocol/SmmPeriodicTimerDispatch2.h>
#include "logging/logging.h"

STATIC EFI_MM_CPU_IO_PROTOCOL *mMmCpuIo;
typedef void *PVOID;
EFI_SMM_SYSTEM_TABLE2 *gSmst = NULL;
// From memory_log.c, we need access to the global buffer address
// We use an extern declaration to make it accessible here.
extern EFI_PHYSICAL_ADDRESS gMemoryLogBufferAddress;

// This is the unique GUID for our UEFI variable.
// {71245e36-47a7-4458-8588-74a4411b9332}
STATIC EFI_GUID gPloutonLogAddressGuid =
    {0x71245e36, 0x47a7, 0x4458, {0x85, 0x88, 0x74, 0xa4, 0x41, 0x1b, 0x93, 0x32}};

// periodic timer global vars
EFI_HANDLE m_PeriodicTimerDispatchHandle = NULL;
EFI_SMM_PERIODIC_TIMER_DISPATCH2_PROTOCOL *m_PeriodicTimerDispatch = NULL;

/*
    SMM periodic timer registration context with Period and TickInterval values.
    Read EFI_SMM_PERIODIC_TIMER_DISPATCH2_PROTOCOL description information volume 4
    of Platform Initialization Specification for more information about them.
*/
EFI_SMM_PERIODIC_TIMER_REGISTER_CONTEXT m_PeriodicTimerDispatch2RegCtx = {1000000, 640000};

EFI_STATUS EFIAPI PeriodicTimerDispatch2Handler(EFI_HANDLE DispatchHandle, CONST VOID *Context, VOID *CommBuffer, UINTN *CommBufferSize)
{
    EFI_STATUS Status = EFI_SUCCESS;
    EFI_SMM_CPU_PROTOCOL *SmmCpu = NULL;

    // obtain SMM CPU protocol
    Status = gSmst->SmmLocateProtocol(&gEfiSmmCpuProtocolGuid, NULL, (PVOID *)&SmmCpu);
    if (Status == EFI_SUCCESS)
    {
        LOG_INFO("Periodic Smi called");
    }
    else
    {
        LOG_INFO("LocateProtocol() fails: 0x%X\r\n", Status);
    }

    return EFI_SUCCESS;
}
//--------------------------------------------------------------------------------------
EFI_STATUS PeriodicTimerDispatch2Register(EFI_HANDLE *DispatchHandle)
{
    EFI_STATUS Status = EFI_INVALID_PARAMETER;

    if (m_PeriodicTimerDispatch == NULL)
    {
        LOG_INFO("[Timer] Register: dispatch protocol is NULL\r\n");
        return EFI_NOT_READY;
    }

    if (DispatchHandle == NULL)
    {
        LOG_INFO("[Timer] Register: DispatchHandle pointer is NULL\r\n");
        return EFI_INVALID_PARAMETER;
    }

    // register periodic timer routine
    Status = m_PeriodicTimerDispatch->Register(
        m_PeriodicTimerDispatch,
        PeriodicTimerDispatch2Handler,
        &m_PeriodicTimerDispatch2RegCtx,
        DispatchHandle);
    if (Status == EFI_SUCCESS)
    {
        LOG_INFO("[Timer] Handler registered OK, handle=0x%p\r\n", *DispatchHandle);
    }
    else
    {
        LOG_INFO("[Timer] Register() ERROR 0x%X\r\n", Status);
    }

    return Status;
}
//--------------------------------------------------------------------------------------
EFI_STATUS PeriodicTimerDispatch2Unregister(EFI_HANDLE DispatchHandle)
{
    EFI_STATUS Status = EFI_INVALID_PARAMETER;

    if (m_PeriodicTimerDispatch == NULL)
    {
        return EFI_NOT_READY;
    }

    // unregister periodic timer routine
    Status = m_PeriodicTimerDispatch->UnRegister(
        m_PeriodicTimerDispatch,
        DispatchHandle);
    if (Status == EFI_SUCCESS)
    {
        LOG_INFO("SMM timer handler unregistered\r\n");
    }
    else
    {
        LOG_INFO("Unregister() fails: 0x%X\r\n", Status);
    }

    return Status;
}
//--------------------------------------------------------------------------------------
EFI_STATUS EFIAPI PeriodicTimerDispatch2ProtocolNotifyHandler(CONST EFI_GUID *Protocol, VOID *Interface, EFI_HANDLE Handle)
{
    EFI_STATUS Status = EFI_SUCCESS;

    // obtain target protocol
    m_PeriodicTimerDispatch =
        (EFI_SMM_PERIODIC_TIMER_DISPATCH2_PROTOCOL *)Interface;

    // enable periodic timer SMI
    // PeriodicTimerDispatch2Register(&m_PeriodicTimerDispatchHandle);
    Status = PeriodicTimerDispatch2Register(
        &m_PeriodicTimerDispatchHandle);

    if (EFI_ERROR(Status))
    {
        LOG_INFO("[Notify] Failed to register timer: 0x%X\r\n", Status);
    }

    return EFI_SUCCESS;
}
//--------------------------------------------------------------------------------------

EFI_STATUS EFIAPI SmiHandler(IN EFI_HANDLE DispatchHandle, IN CONST VOID *RegisterContext, IN OUT VOID *CommBuffer, IN OUT UINTN *CommBufferSize)
{
    EFI_STATUS status;
    UINT8 commandNumber;

    //
    // Read the SMI command value from the power management port. This port can
    // be different on the other platforms, but this works on my target and all
    // Intel systems I have. You may fetch the AX register value to check this
    // using gEfiMmCpuProtocolGuid.
    //
    status = mMmCpuIo->Io.Read(mMmCpuIo, MM_IO_UINT8, ICH9_APM_CNT, 1, &commandNumber);
    ASSERT_EFI_ERROR(status);

    //
    // For the demonstration purpose ignore 0xff, which is pretty busy SMI.
    //
    if (commandNumber == 0xff)
    {
        goto Exit;
    }

    if (commandNumber == 0x33)
    {
        PVOID Registration = NULL;
        status = gSmst->SmmRegisterProtocolNotify(
            &gEfiSmmPeriodicTimerDispatch2ProtocolGuid,
            PeriodicTimerDispatch2ProtocolNotifyHandler,
            &Registration);
        if (status == EFI_SUCCESS)
        {
            LOG_INFO("SMM protocol notify handler is at PeriodicTimerDispatch2ProtocolNotifyHandler \r\n");
        }
        else
        {
            LOG_INFO("RegisterProtocolNotify() fails: 0x%X\r\n", status);
        }
    }

    LOG_INFO("[HelloSmm] SMI 0x%02x\n", commandNumber);

    DEBUG((EFI_D_INFO, "[HelloSmm] SMI 0x%02x\n", commandNumber));

Exit:
    //
    // Allow other SMI to run.
    //
    return EFI_WARN_INTERRUPT_SOURCE_QUIESCED;
}

EFI_STATUS EFIAPI HelloSmmInitialize(IN EFI_HANDLE ImageHandle, IN EFI_SYSTEM_TABLE *SystemTable)
{
    EFI_STATUS status;
    EFI_HANDLE dispatchHandle;

    // EFI_SYSTEM_TABLE *lST = SystemTable;
    EFI_RUNTIME_SERVICES *lRS = SystemTable->RuntimeServices;
    EFI_BOOT_SERVICES *lBS = SystemTable->BootServices;

    // =====================================================
    // First: Determine if we are in SMM
    // =====================================================

    BOOLEAN bInSmram = FALSE;
    EFI_SMM_BASE2_PROTOCOL *SmmBase = NULL;

    status = lBS->LocateProtocol(&gEfiSmmBase2ProtocolGuid, NULL, (VOID **)&SmmBase);

    if (EFI_ERROR(status))
    {
        return status;
    }

    SmmBase->InSmm(SmmBase, &bInSmram);

    if (!bInSmram)
    {
        // We will return as we dont need to setup anything in dxe phase.
        return EFI_SUCCESS;
    }

    // =====================================================
    // We are now running in SMRAM context.
    // All global variable writes go to the SMRAM copy.
    // =====================================================
    status = SmmBase->GetSmstLocation(SmmBase, &gSmst);

    if (EFI_ERROR(status))
    {
        return status;
    }

    // ***************************************************
    // * Initialize Memory Logging
    // ***************************************************
    if (EFI_ERROR(InitMemoryLog(lBS)))
    {
        // If memory logging fails, we can't continue as the user has no other way to debug.
        return EFI_DEVICE_ERROR;
    }

    // ***************************************************
    // * Store Log Buffer Address in a UEFI Variable
    // ***************************************************
    if (gMemoryLogBufferAddress != 0)
    {
        status = lRS->SetVariable(
            L"PloutonLogAddress",
            &gPloutonLogAddressGuid,
            EFI_VARIABLE_BOOTSERVICE_ACCESS | EFI_VARIABLE_RUNTIME_ACCESS,
            sizeof(EFI_PHYSICAL_ADDRESS),
            &gMemoryLogBufferAddress);

        if (EFI_ERROR(status))
        {
            LOG_ERROR("[HelloSmm] Failed to set UEFI variable for log address. Status: %r\n", status);
            // This is not a fatal error, the log still works, but it will be hard to find.
        }
        else
        {
            LOG_INFO("[HelloSmm] Log address 0x%llx stored in UEFI variable 'PloutonLogAddress'.\n", gMemoryLogBufferAddress);
        }
    }

    LOG_INFO("[HelloSmm] HelloSmmInitialize called (in SMRAM)\n");

    status = gMmst->MmLocateProtocol(&gEfiMmCpuIoProtocolGuid, NULL, (VOID **)&mMmCpuIo);
    ASSERT_EFI_ERROR(status);

    //
    // Register the root SMI handler.
    //
    status = gMmst->MmiHandlerRegister(SmiHandler, NULL, &dispatchHandle);
    ASSERT_EFI_ERROR(status);

    return status;
}
